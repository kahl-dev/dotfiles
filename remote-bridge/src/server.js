#!/usr/bin/env node

const express = require('express');
const bodyParser = require('body-parser');
const { loadConfig } = require('./utils/config');
const { createLogger } = require('./utils/logger');
const { loadPlugins } = require('./utils/plugin-loader');
const { resolveExpectedToken } = require('./utils/token');
const base64Middleware = require('./middleware/base64');
const { createAuthMiddleware } = require('./middleware/auth');
const rateLimitMiddleware = require('./middleware/rate-limit');
const validationMiddleware = require('./middleware/validation');

// Shared by every error path that turns a caught error into an HTTP
// response (wrapHandler, /history, the generic Express error middleware).
// Errors below 500 (e.g. a plugin's validation throw) surface their own
// message; 500s are masked to avoid leaking internals to the client.
function respondWithError(res, err) {
  const status = err.status || err.statusCode || 500;
  res.status(status).json({ error: status < 500 ? err.message : 'Internal server error' });
}

class RemoteBridgeServer {
  constructor() {
    this.app = express();
    this.config = null;
    this.logger = null;
    this.plugins = new Map();
    this.handlers = new Map();
  }

  async initialize() {
    // Load configuration
    this.config = await loadConfig();
    this.logger = createLogger(this.config.logging);

    this.logger.info('Starting Remote Bridge Server...');

    // Fail closed: refuse to start unauthenticated when no token is available.
    // A whitespace-only token is treated the same as an unset one — it's not
    // a usable secret (an atuin var set to blank/padded content resolves to
    // one), so starting the server "authenticated" on it would be misleading.
    const { token, error: tokenError } = resolveExpectedToken();
    if (tokenError) {
      // Distinguishes "atuin not authenticated" / "atuin missing" from a
      // plain unset var — never logs the token value itself.
      this.logger.error('Token resolution via atuin failed', { error: tokenError.message });
    }
    this.expectedToken = token;
    if (!this.expectedToken || !this.expectedToken.trim()) {
      this.logger.error('REMOTE_BRIDGE_TOKEN not found (env or atuin) — run: atuin dotfiles var set REMOTE_BRIDGE_TOKEN <value>');
      process.exit(1);
    }

    // Setup middleware
    this.setupMiddleware();

    // Load plugins
    await this.loadPlugins();

    // Setup core routes
    this.setupRoutes();

    // Start server
    await this.start();
  }

  setupMiddleware() {
    this.app.use(bodyParser.json({ limit: '10mb' }));
    this.app.use(base64Middleware);
    this.app.use(createAuthMiddleware(this.expectedToken));
    this.app.use(rateLimitMiddleware(this.config.rateLimit));
    this.app.use(validationMiddleware);
    
    // Request logging
    this.app.use((req, res, next) => {
      const startTime = Date.now();
      res.on('finish', () => {
        const duration = Date.now() - startTime;
        this.logger.info('Request', {
          method: req.method,
          path: req.path,
          status: res.statusCode,
          duration: `${duration}ms`,
          host: req.body?.metadata?.host,
          session: req.body?.metadata?.session
        });
      });
      next();
    });
  }

  async loadPlugins() {
    // Load core plugins
    const corePlugins = ['clipboard', 'browser', 'notify', 'time-tracking'];
    for (const name of corePlugins) {
      try {
        const plugin = require(`./plugins/${name}`);
        await this.registerPlugin(plugin);
      } catch (error) {
        this.logger.error(`Failed to load core plugin ${name}:`, error);
      }
    }
    
    // Load user plugins
    const userPlugins = await loadPlugins(this.config.plugins);
    for (const plugin of userPlugins) {
      await this.registerPlugin(plugin);
    }
  }

  async registerPlugin(plugin) {
    this.logger.info(`Registering plugin: ${plugin.name}`);
    this.plugins.set(plugin.name, plugin);
    
    // Register endpoints
    if (plugin.endpoints) {
      for (const endpoint of plugin.endpoints) {
        this.app[endpoint.method.toLowerCase()](
          endpoint.path,
          this.wrapHandler(endpoint.handler, plugin)
        );
      }
    }
    
    // Initialize plugin if needed
    if (plugin.initialize) {
      await plugin.initialize(this);
    }
  }

  wrapHandler(handler, plugin) {
    return async (req, res, next) => {
      try {
        // Run before hooks
        const hookResult = await this.runHooks(`before${req.path}`, req.body, req.metadata);
        if (hookResult === false) {
          return res.status(403).json({ error: 'Blocked by hook' });
        }
        
        // Run handler
        await handler.call(plugin, req, res);
        
        // Run after hooks
        await this.runHooks(`after${req.path}`, req.body, req.metadata, res.result);
      } catch (error) {
        this.logger.error(`Handler error: ${error.message}`, { error, path: req.path });
        if (!res.headersSent) {
          respondWithError(res, error);
        }
      }
    };
  }

  async runHooks(hookName, ...args) {
    for (const [name, plugin] of this.plugins) {
      if (plugin.hooks && plugin.hooks[hookName]) {
        try {
          const result = await plugin.hooks[hookName](...args);
          if (result === false) return false;
          if (result !== undefined) args[0] = result;
        } catch (error) {
          this.logger.error(`Hook error in ${name}.${hookName}:`, error);
        }
      }
    }
    return args[0];
  }

  setupRoutes() {
    // Health check
    this.app.get('/health', (req, res) => {
      res.json({ 
        status: 'ok', 
        version: '1.0.0',
        uptime: process.uptime(),
        plugins: Array.from(this.plugins.keys())
      });
    });
    
    // History endpoint
    this.app.get('/history', async (req, res) => {
      try {
        const limit = parseInt(req.query.limit) || 50;
        const history = await this.logger.getHistory(limit);
        res.json(history);
      } catch (error) {
        this.logger.error(`History error: ${error.message}`, { error });
        respondWithError(res, error);
      }
    });
    
    // 404 handler
    this.app.use((req, res) => {
      res.status(404).json({ error: 'Endpoint not found' });
    });
    
    // Error handler
    this.app.use((err, req, res, next) => {
      this.logger.error('Unhandled error:', err);
      respondWithError(res, err);
    });
  }

  async start() {
    const port = this.config.service.port || 8377;
    
    return new Promise((resolve, reject) => {
      this.server = this.app.listen(port, 'localhost', (err) => {
        if (err) {
          this.logger.error('Failed to start server:', err);
          reject(err);
        } else {
          this.logger.info(`Remote Bridge Server listening on localhost:${port}`);
          resolve();
        }
      });
    });
  }

  async stop() {
    if (this.server) {
      return new Promise((resolve) => {
        this.server.close(() => {
          this.logger.info('Server stopped');
          resolve();
        });
      });
    }
  }
}

// Handle process signals
let server;

async function shutdown(signal) {
  console.log(`\nReceived ${signal}, shutting down...`);
  if (server) {
    await server.stop();
  }
  process.exit(0);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

// Start server
if (require.main === module) {
  server = new RemoteBridgeServer();
  server.initialize().catch(error => {
    console.error('Failed to start server:', error);
    process.exit(1);
  });
}

module.exports = RemoteBridgeServer;
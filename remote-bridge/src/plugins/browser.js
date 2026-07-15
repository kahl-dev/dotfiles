const open = require('open').default || require('open');

const ALLOWED_PROTOCOLS = ['http:', 'https:'];

/**
 * Parse and validate a URL before it's handed to the OS opener. Rejects any
 * scheme other than http/https — file:, javascript:, and similar schemes
 * let a remote caller open local files or trigger OS-handler side effects
 * on the machine running this bridge.
 */
function validateUrl(url) {
  let parsed;
  try {
    parsed = new URL(url);
  } catch (error) {
    throw new Error(`Invalid URL: ${error.message}`);
  }

  if (!ALLOWED_PROTOCOLS.includes(parsed.protocol)) {
    throw new Error(`Rejected URL scheme: ${parsed.protocol}`);
  }

  return parsed;
}

/**
 * Validate the client-supplied app name before it's handed to `open()`.
 * `open(url, { app: { name } })` shells out to the OS opener with whatever
 * name it's given — an authenticated caller could otherwise launch any
 * installed application by name. Require a plain app name: a string with no
 * path separator and no newline, never a path or embedded command.
 */
function validateAppOption(app) {
  if (typeof app !== 'string' || app.includes('/') || app.includes('\n')) {
    throw new Error('Invalid app option');
  }
  return app;
}

module.exports = {
  name: 'browser',
  version: '1.0.0',

  // Exported for unit testing the guards directly.
  validateUrl,
  validateAppOption,

  endpoints: [
    {
      path: '/browser',
      method: 'POST',
      handler: async function(req, res) {
        try {
          const url = req.decodedData;
          const metadata = req.metadata;
          const options = req.body.options || {};

          validateUrl(url);
          if (options.app !== undefined) {
            validateAppOption(options.app);
          }

          // Open URL
          await open(url, {
            wait: false,
            ...(options.app && { app: { name: options.app } })
          });

          // Store result
          res.result = {
            success: true,
            url
          };
          
          // Log
          this.server.logger.info('URL opened', {
            host: metadata.host,
            session: metadata.session,
            url,
            app: options.app || 'default'
          });
          
          res.json(res.result);
          
        } catch (error) {
          throw new Error(`Failed to open URL: ${error.message}`);
        }
      }
    }
  ],
  
  initialize: function(server) {
    this.server = server;
  }
};
// Exercises src/plugins/time-tracking.js's registration in isolation from a
// broken v2 module (review finding WARNING 6): if the v2 module (and its zod
// dependency) fails to load — e.g. a deploy host missing zod — a top-level
// `require('./time-tracking-v2')` in time-tracking.js throws during
// require(plugins/time-tracking), which server.js's loadPlugins() core-plugin
// loop catches by simply never registering the plugin at all (see
// src/server.js loadPlugins()/registerPlugin()). That takes BOTH
// /time-tracking (v1, the designated rollback path) and /time-tracking/v2
// down together — the exact coupling the v1 rollback path exists to avoid.
//
// Runs in a child process (not this test process) because the fix is
// verified by monkey-patching Module._resolveFilename to make every require
// of time-tracking-v2.js throw, simulating "zod is not installed" — patching
// process-wide module resolution in the shared test-runner process would
// leak into every other test file.

const { describe, it, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const PLUGIN_PATH = path.join(__dirname, '..', 'src', 'plugins', 'time-tracking.js');
const V2_MODULE_PATH = path.join(__dirname, '..', 'src', 'plugins', 'time-tracking-v2.js');

// Minimal stand-in for server.js's wrapHandler/respondWithError: catches a
// handler's thrown/rejected error and turns it into a response instead of
// crashing, exactly like production does for every registered endpoint.
const CHILD_SCRIPT = `
const path = require('path');
const Module = require('module');

const v2Path = require.resolve(process.argv[1]);
const pluginPath = process.argv[2];
const originalResolveFilename = Module._resolveFilename;
Module._resolveFilename = function (request, ...rest) {
  const resolved = originalResolveFilename.call(this, request, ...rest);
  if (resolved === v2Path) {
    const error = new Error("Cannot find module 'zod'");
    error.code = 'MODULE_NOT_FOUND';
    throw error;
  }
  return resolved;
};

function makeRes() {
  return {
    statusCode: 200,
    headersSent: false,
    body: null,
    status(code) { this.statusCode = code; return this; },
    json(payload) { this.body = payload; this.headersSent = true; return this; },
  };
}

async function invoke(endpoint, plugin, req) {
  const res = makeRes();
  try {
    await endpoint.handler.call(plugin, req, res);
  } catch (error) {
    if (!res.headersSent) {
      res.status(error.status || 500).json({ error: 'Internal server error' });
    }
  }
  return res;
}

(async () => {
  let plugin;
  let loadError = null;
  try {
    plugin = require(pluginPath);
  } catch (error) {
    loadError = error.message;
  }

  if (loadError) {
    process.stdout.write(JSON.stringify({ loadError }));
    return;
  }

  plugin.server = { logger: { info() {}, error() {} } };
  const v1Endpoint = plugin.endpoints.find((endpoint) => endpoint.path === '/time-tracking');
  const v2Endpoint = plugin.endpoints.find((endpoint) => endpoint.path === '/time-tracking/v2');

  const v1Res = await invoke(v1Endpoint, plugin, { query: { dates: '2026-01-01' } });
  const v2Res = await invoke(v2Endpoint, plugin, { query: { dates: '2026-01-01', harnesses: 'claude' }, originalUrl: '/time-tracking/v2' });

  process.stdout.write(JSON.stringify({
    loadError: null,
    v1Status: v1Res.statusCode,
    v1HasHostname: typeof (v1Res.body && v1Res.body.hostname) === 'string',
    v2Status: v2Res.statusCode,
  }));
})();
`;

describe('time-tracking plugin: v1/v2 load isolation', () => {
  it('keeps the v1 endpoint working when the v2 module fails to load (e.g. zod missing)', () => {
    const output = execFileSync(process.execPath, ['-e', CHILD_SCRIPT, '--', V2_MODULE_PATH, PLUGIN_PATH], { encoding: 'utf-8' });
    const result = JSON.parse(output);

    assert.equal(result.loadError, null, 'requiring the v1 plugin module must not throw even when v2 cannot load');
    assert.equal(result.v1Status, 200, 'the v1 rollback endpoint must keep working when v2 is broken');
    assert.equal(result.v1HasHostname, true);
    assert.notEqual(result.v2Status, 200, 'the v2 endpoint itself must fail gracefully, not silently succeed');
  });
});

// Regression fix: server.js's wrapHandler invokes plugin endpoint handlers as
// `handler.call(plugin, req, res)`, so `this` inside time-tracking.js's
// `/time-tracking/v2` wrapper is the plugin instance. But the wrapper used to
// forward to the v2 module handler via plain property access
// (`require('./time-tracking-v2').handler(req, res)`), which drops that
// binding — `this` inside the v2 handler became the required module object
// (no `.server`), so time-tracking-v2.js's
// `this && this.server && this.server.logger` guard could never be true on a
// real request, silently disabling the source-errors log line the
// lazy-require fix was never meant to remove. The wrapper must forward the
// binding with `.call(this, req, res)`.
//
// Runs in a child process (not this test process) for the same reason as the
// isolation test above: it needs a real HOME so os.homedir()-derived
// TRACKING_DIR points at an isolated fixture directory instead of the
// developer's real ~/.claude/time-tracking.
const LOGGING_CHILD_SCRIPT = `
function makeRes() {
  return {
    statusCode: 200,
    headersSent: false,
    body: null,
    status(code) { this.statusCode = code; return this; },
    json(payload) { this.body = payload; this.headersSent = true; return this; },
  };
}

(async () => {
  const pluginPath = process.argv[1];
  const date = process.argv[2];
  const plugin = require(pluginPath);
  const errorCalls = [];
  plugin.server = { logger: { info() {}, error(...args) { errorCalls.push(args); } } };

  const v2Endpoint = plugin.endpoints.find((endpoint) => endpoint.path === '/time-tracking/v2');
  const res = makeRes();
  await v2Endpoint.handler.call(plugin, { query: { dates: date, harnesses: 'claude' }, originalUrl: '/time-tracking/v2' }, res);

  process.stdout.write(JSON.stringify({ status: res.statusCode, errors: res.body.errors, errorCalls }));
})();
`;

describe('time-tracking plugin: v2 wrapper preserves the plugin binding for logging', () => {
  let homedir;
  let date;

  beforeEach(() => {
    homedir = fs.mkdtempSync(path.join(os.tmpdir(), 'tt-plugin-binding-'));
    // A directory in place of the expected event file forces a non-ENOENT
    // read failure (EISDIR) deterministically and cross-platform, without
    // chmod-based permission tricks (same technique used throughout
    // time-tracking-v2.test.js), which buildFileDescriptor records as a
    // `permissions_invalid` source error.
    date = '2026-01-01';
    fs.mkdirSync(path.join(homedir, '.claude', 'time-tracking', `${date}.jsonl`), { recursive: true });
  });

  afterEach(() => {
    fs.rmSync(homedir, { recursive: true, force: true });
  });

  it('logs exactly once with the source-error count and codes through the real endpoint wrapper', () => {
    const output = execFileSync(
      process.execPath,
      ['-e', LOGGING_CHILD_SCRIPT, '--', PLUGIN_PATH, date],
      { encoding: 'utf-8', env: { ...process.env, HOME: homedir } }
    );
    const result = JSON.parse(output);

    assert.equal(result.status, 200);
    assert.equal(result.errors.length, 1);
    assert.equal(result.errors[0].code, 'permissions_invalid');
    assert.equal(result.errorCalls.length, 1, 'logger.error must be called exactly once for a response with source errors');
    assert.equal(result.errorCalls[0][0], 'time-tracking/v2 returned source errors');
    assert.deepEqual(result.errorCalls[0][1], { count: 1, codes: ['permissions_invalid'] });
  });
});

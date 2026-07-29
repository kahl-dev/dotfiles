// Shared test scaffolding for the Unix-socket bridge tests
// (rtime-fetch-v2.test.js, client-socket-success.test.js,
// time-tracking-v2.test.js): mkTempDir, stopTestBridge, and a parametrized
// startTestBridge were each defined identically (or near-identically) in
// multiple test files. registerRoutes lets each caller wire up its own
// scenario-specific middleware/routes (auth token, body parsing, the
// handler under test) on top of the one thing every bridge fixture needs:
// a listening Express app on a Unix socket with /health answered.

const fs = require('fs');
const os = require('os');
const path = require('path');
const express = require('express');

function mkTempDir(prefix) {
  return fs.mkdtempSync(path.join(os.tmpdir(), prefix));
}

function stopTestBridge(server, socketPath) {
  return new Promise((resolve) => server.close(() => {
    fs.rmSync(socketPath, { force: true });
    resolve();
  }));
}

// registerRoutes(app) attaches whatever auth/body/route middleware the
// calling test needs, after the shared /health route is already in place.
function startTestBridge(socketPath, registerRoutes) {
  const app = express();
  app.get('/health', (req, res) => res.json({ status: 'ok' }));
  registerRoutes(app);

  return new Promise((resolve) => {
    const server = app.listen(socketPath, () => resolve(server));
  });
}

module.exports = { mkTempDir, stopTestBridge, startTestBridge };

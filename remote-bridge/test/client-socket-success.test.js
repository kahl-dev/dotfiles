// Exercises bin/rclip end-to-end over a real Unix domain socket: the
// transport Phase 2 introduces for every non-Darwin host. The stand-in
// bridge below answers /health and /clipboard with the real auth and
// base64 middleware (never mocking our own code), but records the decoded
// clipboard payload instead of calling clipboardy — the real clipboard
// plugin writes to the *system* clipboard (pbcopy/xclip/wl-copy), which is
// unavailable and undesirable in a test sandbox. The fixture plays the
// bridge's role at exactly the layer this phase changes: Unix socket
// transport, auth, and the base64 request envelope.
//
// Uses the async execFile (not execFileSync): the test bridge server runs in
// this same Node process, so a *synchronous* child-process call would block
// the event loop the server needs to answer the request — a deadlock, not a
// flake.

const { describe, it, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFile } = require('child_process');
const { promisify } = require('util');
const express = require('express');
const bodyParser = require('body-parser');

const execFileAsync = promisify(execFile);

const base64Middleware = require('../src/middleware/base64');
const { createAuthMiddleware } = require('../src/middleware/auth');

const RCLIP_BIN = path.join(__dirname, '..', 'bin', 'rclip');
const TEST_TOKEN = 'client-socket-success-test-token';

function mkTempDir(prefix) {
  return fs.mkdtempSync(path.join(os.tmpdir(), prefix));
}

function startTestBridge(socketPath, received) {
  const app = express();
  app.use(bodyParser.json({ limit: '10mb' }));
  app.get('/health', (req, res) => res.json({ status: 'ok' }));
  app.use(createAuthMiddleware(TEST_TOKEN));
  app.use(base64Middleware);
  app.post('/clipboard', (req, res) => {
    received.push({ data: req.decodedData, options: req.body.options, metadata: req.metadata });
    res.json({ success: true, length: req.decodedData.length });
  });

  return new Promise((resolve) => {
    const server = app.listen(socketPath, () => resolve(server));
  });
}

function stopTestBridge(server, socketPath) {
  return new Promise((resolve) => server.close(() => {
    fs.rmSync(socketPath, { force: true });
    resolve();
  }));
}

describe('bridge clients over a Unix socket (rclip end-to-end)', () => {
  let socketDir;
  let socketPath;
  let server;
  let received;

  beforeEach(async () => {
    socketDir = mkTempDir('client-socket-success-');
    socketPath = path.join(socketDir, 'bridge.sock');
    received = [];
    server = await startTestBridge(socketPath, received);
  });

  afterEach(async () => {
    await stopTestBridge(server, socketPath);
    fs.rmSync(socketDir, { recursive: true, force: true });
  });

  function runRclip(args, extraEnv = {}) {
    return execFileAsync(RCLIP_BIN, args, {
      env: {
        ...process.env,
        REMOTE_BRIDGE_SOCKET: socketPath,
        REMOTE_BRIDGE_TOKEN: TEST_TOKEN,
        ...extraEnv,
      },
      encoding: 'utf-8',
    });
  }

  it('reaches /health over the Unix socket and delivers the payload through /clipboard', async () => {
    const { stdout } = await runRclip(['hello over the unix socket']);

    assert.match(stdout, /Clipboard updated/);
    assert.equal(received.length, 1);
    assert.equal(received[0].data, 'hello over the unix socket');
    assert.equal(received[0].options.type, 'text');
  });

  it('surfaces the bridge auth error distinctly from a connection failure when the token is wrong', async () => {
    await assert.rejects(
      runRclip(['hello'], { REMOTE_BRIDGE_TOKEN: 'wrong-token' }),
      (error) => {
        assert.notEqual(error.code, 0);
        assert.match(error.stderr.toString(), /unauthorized/);
        return true;
      }
    );
    assert.equal(received.length, 0, 'a rejected request must never reach the clipboard handler');
  });
});

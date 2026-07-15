const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const express = require('express');
const bodyParser = require('body-parser');
const supertest = require('supertest');
const base64Middleware = require('../src/middleware/base64');
const obsidianPlugin = require('../../.config/remote-bridge/plugins/obsidian');
const notifyPlugin = require('../src/plugins/notify');
const browserPlugin = require('../src/plugins/browser');
const createRateLimiter = require('../src/middleware/rate-limit');

// Mirrors production's wrapHandler (src/server.js): catches thrown errors from
// the handler and turns them into a 500, so handlers that validate-then-throw
// (browser.js, notify.js) behave the same under test as they do in the real server.
function createTestApp(plugin) {
  const app = express();
  app.use(bodyParser.json({ limit: '10mb' }));
  app.use(base64Middleware);

  for (const endpoint of plugin.endpoints) {
    app[endpoint.method.toLowerCase()](
      endpoint.path,
      async (request, response) => {
        try {
          await endpoint.handler.call(plugin, request, response);
        } catch (error) {
          response.status(500).json({ error: error.message });
        }
      }
    );
  }

  return app;
}

function encodeCommand(command) {
  return Buffer.from(command).toString('base64');
}

function makeTempVault() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'obsidian-vault-'));
}

describe('obsidian plugin: path traversal guard (handleStdinCommand)', () => {
  it('rejects a create path that escapes the vault directory and writes no file outside it', () => {
    const vaultPath = makeTempVault();

    assert.throws(
      () => obsidianPlugin.handleStdinCommand(['create', 'path=../../escape.md'], 'pwned content', vaultPath),
      /Path escapes vault: \.\.\/\.\.\/escape\.md/
    );

    const escapedPath = path.resolve(vaultPath, '../../escape.md');
    assert.equal(fs.existsSync(escapedPath), false);
  });

  it('rejects an append path that escapes the vault directory', () => {
    const vaultPath = makeTempVault();

    assert.throws(
      () => obsidianPlugin.handleStdinCommand(['append', 'path=../outside.md'], 'pwned', vaultPath),
      /Path escapes vault: \.\.\/outside\.md/
    );
  });

  it('still allows a normal nested path inside the vault', () => {
    const vaultPath = makeTempVault();

    const result = obsidianPlugin.handleStdinCommand(['create', 'path=notes/todo.md'], 'buy milk', vaultPath);

    assert.equal(result.exitCode, 0);
    assert.equal(fs.readFileSync(path.join(vaultPath, 'notes/todo.md'), 'utf-8'), 'buy milk');
  });

  it('still creates "name 1.md" for a duplicate in-vault path instead of overwriting', () => {
    const vaultPath = makeTempVault();
    fs.writeFileSync(path.join(vaultPath, 'daily.md'), 'original', 'utf-8');

    const result = obsidianPlugin.handleStdinCommand(['create', 'path=daily.md'], 'new content', vaultPath);

    assert.equal(result.exitCode, 0);
    assert.equal(result.stdout, 'Created: daily 1.md\n');
    assert.equal(fs.readFileSync(path.join(vaultPath, 'daily.md'), 'utf-8'), 'original');
    assert.equal(fs.readFileSync(path.join(vaultPath, 'daily 1.md'), 'utf-8'), 'new content');
  });
});

describe('obsidian plugin: assertPathInVault', () => {
  it('rejects a path that escapes the vault directory via ../', () => {
    const vaultPath = makeTempVault();

    assert.throws(
      () => obsidianPlugin.assertPathInVault(vaultPath, '../x'),
      /Path escapes vault: \.\.\/x/
    );
  });

  it('rejects an absolute path outside the vault', () => {
    const vaultPath = makeTempVault();

    assert.throws(
      () => obsidianPlugin.assertPathInVault(vaultPath, '/etc/x'),
      /Path escapes vault: \/etc\/x/
    );
  });

  it('rejects the vault root itself (".")', () => {
    const vaultPath = makeTempVault();

    assert.throws(
      () => obsidianPlugin.assertPathInVault(vaultPath, '.'),
      /Path escapes vault: \./
    );
  });

  it('accepts a normal path nested inside the vault', () => {
    const vaultPath = makeTempVault();

    const resolved = obsidianPlugin.assertPathInVault(vaultPath, 'notes/x.md');

    assert.equal(resolved, path.join(vaultPath, 'notes/x.md'));
  });
});

describe('obsidian plugin: non-stdin commands reject a path= that escapes the vault', () => {
  it('rejects a "delete path=../../escape.md" request with HTTP 400 before touching the CLI', async () => {
    const app = createTestApp(obsidianPlugin);

    const response = await supertest(app)
      .post('/obsidian/exec')
      .send({
        data: encodeCommand('delete path=../../escape.md'),
        metadata: { host: 'test', user: 'test' },
      })
      .expect(400);

    assert.match(response.body.error, /Path escapes vault: \.\.\/\.\.\/escape\.md/);
  });

  it('rejects a "move" request whose to= argument escapes the vault', async () => {
    const app = createTestApp(obsidianPlugin);

    const response = await supertest(app)
      .post('/obsidian/exec')
      .send({
        data: encodeCommand('move path=notes/a.md to=../../escape.md'),
        metadata: { host: 'test', user: 'test' },
      })
      .expect(400);

    assert.match(response.body.error, /Path escapes vault: \.\.\/\.\.\/escape\.md/);
  });

  it('rejects a non-stdin "create path=." request instead of writing outside the vault', async () => {
    const app = createTestApp(obsidianPlugin);

    const response = await supertest(app)
      .post('/obsidian/exec')
      .send({
        data: encodeCommand('create path=. content=hello'),
        metadata: { host: 'test', user: 'test' },
      })
      .expect(400);

    assert.match(response.body.error, /Path escapes vault: \./);
  });
});

describe('notify plugin: osascript argv builder (no shell injection)', () => {
  it('builds a 2-element argv array where a shell-breakout payload stays literal data', () => {
    const maliciousMessage = "hello'; touch /tmp/pwned; '";

    const args = notifyPlugin.buildOsascriptArgs({
      message: maliciousMessage,
      title: 'Remote Bridge',
      sound: 'Pop',
    });

    assert.equal(Array.isArray(args), true);
    assert.equal(args.length, 2);
    assert.equal(args[0], '-e');
    assert.equal(typeof args[1], 'string');
    assert.ok(args[1].includes(maliciousMessage), 'payload must appear verbatim as AppleScript string data, not be stripped or split');
  });

  it('escapes embedded double quotes so the AppleScript string literal cannot be broken out of', () => {
    const args = notifyPlugin.buildOsascriptArgs({
      message: 'say "hi"',
      title: 'Title',
      sound: 'Pop',
    });

    assert.ok(args[1].includes('say \\"hi\\"'));
  });

  it('responds 400 instead of throwing a TypeError when metadata.session is missing', async () => {
    notifyPlugin.initialize({ config: {}, logger: { info() {} } });
    const app = createTestApp(notifyPlugin);

    const response = await supertest(app)
      .post('/notify')
      .send({
        data: encodeCommand('hello world'),
        metadata: { host: 'test' },
      })
      .expect(400);

    assert.equal(typeof response.body.error, 'string');
    assert.match(response.body.error, /session/);
  });
});

describe('browser plugin: validateUrl', () => {
  it('accepts http and https URLs and returns the parsed URL', () => {
    const parsedHttps = browserPlugin.validateUrl('https://example.com/path');
    assert.equal(parsedHttps.protocol, 'https:');
    assert.equal(parsedHttps.href, 'https://example.com/path');

    const parsedHttp = browserPlugin.validateUrl('http://example.com/');
    assert.equal(parsedHttp.protocol, 'http:');
  });

  it('rejects a file: URL with a scheme-specific error', () => {
    assert.throws(() => browserPlugin.validateUrl('file:///etc/passwd'), /file:/);
  });

  it('rejects a javascript: URL with a scheme-specific error', () => {
    assert.throws(() => browserPlugin.validateUrl('javascript:alert(1)'), /javascript:/);
  });

  it('rejects a file: URL via the HTTP handler even when the request sets noValidate', async () => {
    browserPlugin.initialize({ logger: { info() {} } });
    const app = createTestApp(browserPlugin);

    const response = await supertest(app)
      .post('/browser')
      .send({
        data: encodeCommand('file:///etc/passwd'),
        metadata: { host: 'test', session: 'test' },
        options: { noValidate: true },
      })
      .expect(500);

    assert.match(response.body.error, /file:/);
  });
});

describe('browser plugin: validateAppOption', () => {
  it('accepts a plain application name', () => {
    assert.equal(browserPlugin.validateAppOption('Google Chrome'), 'Google Chrome');
  });

  it('rejects an app value containing a path separator', () => {
    assert.throws(() => browserPlugin.validateAppOption('/Applications/Evil.app'), /Invalid app option/);
  });

  it('rejects an app value containing a newline', () => {
    assert.throws(() => browserPlugin.validateAppOption('Safari\nrm -rf /'), /Invalid app option/);
  });

  it('rejects a non-string app value', () => {
    assert.throws(() => browserPlugin.validateAppOption({ name: 'Safari' }), /Invalid app option/);
  });

  it('rejects an arbitrary app name via the HTTP handler when it contains a path separator', async () => {
    browserPlugin.initialize({ logger: { info() {} } });
    const app = createTestApp(browserPlugin);

    const response = await supertest(app)
      .post('/browser')
      .send({
        data: encodeCommand('https://example.com'),
        metadata: { host: 'test', session: 'test' },
        options: { app: '/Applications/Terminal.app/Contents/MacOS/Terminal' },
      })
      .expect(500);

    assert.match(response.body.error, /Invalid app option/);
  });
});

describe('rate-limit middleware: keyGenerator ignores client-supplied host', () => {
  it('returns the same key for two requests sharing an IP but differing only in body.metadata.host', () => {
    const { keyGenerator } = createRateLimiter;

    const reqA = { ip: '203.0.113.5', body: { metadata: { host: 'attacker-controlled-host-1' } } };
    const reqB = { ip: '203.0.113.5', body: { metadata: { host: 'attacker-controlled-host-2' } } };

    assert.equal(keyGenerator(reqA), keyGenerator(reqB));
    assert.equal(keyGenerator(reqA), '203.0.113.5');
  });

  it('still returns a working express middleware factory', () => {
    const limiter = createRateLimiter({ windowMs: 1000, maxRequests: 2 });

    assert.equal(typeof limiter, 'function');
  });
});

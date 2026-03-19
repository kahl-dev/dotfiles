const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const bodyParser = require('body-parser');
const supertest = require('supertest');
const base64Middleware = require('../src/middleware/base64');

function createTestApp(plugin) {
  const app = express();
  app.use(bodyParser.json({ limit: '10mb' }));
  app.use(base64Middleware);

  for (const endpoint of plugin.endpoints) {
    app[endpoint.method.toLowerCase()](
      endpoint.path,
      async (request, response) => {
        await endpoint.handler.call(plugin, request, response);
      }
    );
  }

  return app;
}

function encodeCommand(command) {
  return Buffer.from(command).toString('base64');
}

describe('obsidian bridge plugin', () => {
  it('returns wrapped JSON with stdout, stderr, and exitCode fields', async () => {
    const plugin = require('../../.config/remote-bridge/plugins/obsidian');
    const app = createTestApp(plugin);

    const response = await supertest(app)
      .post('/obsidian/exec')
      .send({
        data: encodeCommand('version'),
        metadata: { host: 'test', user: 'test' },
      })
      .expect(200);

    assert.equal(typeof response.body.stdout, 'string');
    assert.equal(typeof response.body.stderr, 'string');
    assert.equal(typeof response.body.exitCode, 'number');
  });

  it('returns error output in stdout for unknown obsidian commands', async () => {
    const plugin = require('../../.config/remote-bridge/plugins/obsidian');
    const app = createTestApp(plugin);

    const response = await supertest(app)
      .post('/obsidian/exec')
      .send({
        data: encodeCommand('nonexistent-command'),
        metadata: { host: 'test', user: 'test' },
      })
      .expect(200);

    assert.equal(response.body.exitCode, 0);
    assert.ok(response.body.stdout.includes('not found'));
  });

  it('returns stdout content from a successful command', async () => {
    const plugin = require('../../.config/remote-bridge/plugins/obsidian');
    const app = createTestApp(plugin);

    const response = await supertest(app)
      .post('/obsidian/exec')
      .send({
        data: encodeCommand('vault'),
        metadata: { host: 'test', user: 'test' },
      })
      .expect(200);

    assert.equal(response.body.exitCode, 0);
    assert.ok(response.body.stdout.includes('kahl_dev'));
  });

  it('returns HTTP 400 when no command data is provided', async () => {
    const plugin = require('../../.config/remote-bridge/plugins/obsidian');
    const app = createTestApp(plugin);

    const response = await supertest(app)
      .post('/obsidian/exec')
      .send({
        metadata: { host: 'test', user: 'test' },
      })
      .expect(400);

    assert.ok(response.body.error);
  });

  it('handles commands with quoted arguments', async () => {
    const plugin = require('../../.config/remote-bridge/plugins/obsidian');
    const app = createTestApp(plugin);

    const response = await supertest(app)
      .post('/obsidian/exec')
      .send({
        data: encodeCommand('search query="daily notes" format=json'),
        metadata: { host: 'test', user: 'test' },
      })
      .expect(200);

    assert.equal(typeof response.body.stdout, 'string');
    assert.equal(response.body.exitCode, 0);
  });

  it('responds quickly when Obsidian is already running (auto-start fast path)', async () => {
    const plugin = require('../../.config/remote-bridge/plugins/obsidian');
    const app = createTestApp(plugin);

    const start = Date.now();
    const response = await supertest(app)
      .post('/obsidian/exec')
      .send({
        data: encodeCommand('vault'),
        metadata: { host: 'test', user: 'test' },
      })
      .expect(200);

    const duration = Date.now() - start;
    assert.equal(response.body.exitCode, 0);
    // Fast path should complete well under 3 seconds
    assert.ok(duration < 3000, `Took ${duration}ms — auto-start check should be instant`);
  });
});

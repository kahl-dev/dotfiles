const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const supertest = require('supertest');
const { createAuthMiddleware } = require('../src/middleware/auth');

const TEST_TOKEN = 'test-token-1234567890';

function createTestApp(expectedToken) {
  const app = express();
  app.use(createAuthMiddleware(expectedToken));
  app.get('/health', (req, res) => res.json({ status: 'ok' }));
  app.get('/protected', (req, res) => res.json({ status: 'ok' }));
  return app;
}

describe('auth middleware', () => {
  it('allows a request with the correct Bearer token', async () => {
    const app = createTestApp(TEST_TOKEN);

    const response = await supertest(app)
      .get('/protected')
      .set('Authorization', `Bearer ${TEST_TOKEN}`)
      .expect(200);

    assert.deepEqual(response.body, { status: 'ok' });
  });

  it('rejects a request with no Authorization header', async () => {
    const app = createTestApp(TEST_TOKEN);

    const response = await supertest(app)
      .get('/protected')
      .expect(401);

    assert.deepEqual(response.body, { error: 'unauthorized' });
  });

  it('rejects a shorter wrong token without throwing on length mismatch', async () => {
    const app = createTestApp(TEST_TOKEN);

    const response = await supertest(app)
      .get('/protected')
      .set('Authorization', 'Bearer short')
      .expect(401);

    assert.deepEqual(response.body, { error: 'unauthorized' });
  });

  it('rejects a longer wrong token without throwing on length mismatch', async () => {
    const app = createTestApp(TEST_TOKEN);

    const response = await supertest(app)
      .get('/protected')
      .set('Authorization', `Bearer ${TEST_TOKEN}-plus-extra-characters-appended`)
      .expect(401);

    assert.deepEqual(response.body, { error: 'unauthorized' });
  });

  it('allows GET /health without a token', async () => {
    const app = createTestApp(TEST_TOKEN);

    const response = await supertest(app)
      .get('/health')
      .expect(200);

    assert.deepEqual(response.body, { status: 'ok' });
  });

  it('rejects an empty Bearer token without matching an empty expected token', async () => {
    const app = createTestApp(TEST_TOKEN);

    const response = await supertest(app)
      .get('/protected')
      .set('Authorization', 'Bearer ')
      .expect(401);

    assert.deepEqual(response.body, { error: 'unauthorized' });
  });
});

describe('createAuthMiddleware fail-closed construction guard', () => {
  it('throws when built with an empty string token', () => {
    assert.throws(
      () => createAuthMiddleware(''),
      /refusing to build with an empty expected token/
    );
  });

  it('throws when built with a whitespace-only token', () => {
    assert.throws(
      () => createAuthMiddleware('   '),
      /refusing to build with an empty expected token/
    );
  });

  it('throws when built with an undefined token', () => {
    assert.throws(
      () => createAuthMiddleware(undefined),
      /refusing to build with an empty expected token/
    );
  });
});

const crypto = require('crypto');

const BEARER_PATTERN = /^Bearer (.+)$/;

function extractBearerToken(authorizationHeader) {
  if (!authorizationHeader) {
    return '';
  }
  const match = authorizationHeader.match(BEARER_PATTERN);
  return match ? match[1] : '';
}

// crypto.timingSafeEqual throws RangeError when the two buffers differ in
// length, which would otherwise let a caller learn the token's length from
// whether the request throws. Hashing both sides to a fixed 32-byte SHA-256
// digest first removes the length variable, so the timingSafeEqual call
// underneath always compares equal-length buffers and stays constant-time.
function timingSafeTokenEqual(providedToken, expectedToken) {
  const providedDigest = crypto.createHash('sha256').update(providedToken).digest();
  const expectedDigest = crypto.createHash('sha256').update(expectedToken).digest();
  return crypto.timingSafeEqual(providedDigest, expectedDigest);
}

// Factory so tests can inject a known token instead of depending on the
// server's startup token resolution (env var or atuin lookup).
function createAuthMiddleware(expectedToken) {
  // Fail-closed guard: timingSafeTokenEqual('', '') is true (both hash to the
  // same SHA-256 digest), so a middleware built with an empty/whitespace
  // token would authenticate an empty Bearer token. The server already
  // fail-closes at startup, but this guard belongs here too as defense-in-depth.
  if (typeof expectedToken !== 'string' || expectedToken.trim() === '') {
    throw new Error('createAuthMiddleware: refusing to build with an empty expected token (fail-closed)');
  }

  return function authMiddleware(req, res, next) {
    // The SSH tunnel health check hits GET /health with no way to carry a
    // token, so it must stay reachable without one.
    if (req.method === 'GET' && req.path === '/health') {
      return next();
    }

    const providedToken = extractBearerToken(req.get('Authorization'));

    if (!providedToken || !timingSafeTokenEqual(providedToken, expectedToken)) {
      return res.status(401).json({ error: 'unauthorized' });
    }

    next();
  };
}

module.exports = { createAuthMiddleware };

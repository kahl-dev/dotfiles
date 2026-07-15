const rateLimit = require('express-rate-limit');

// Key on the connection IP only. req.body.metadata.host is client-supplied —
// keying on it let any client dodge the limit by varying the host per
// request, since each distinct host value got its own bucket.
function keyGenerator(req) {
  return req.ip;
}

module.exports = function createRateLimiter(config = {}) {
  const windowMs = config.windowMs || 60000; // 1 minute
  const maxRequests = config.maxRequests || 60;

  return rateLimit({
    windowMs,
    max: maxRequests,
    message: 'Too many requests, please try again later',
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator,
  });
};

// Exported for unit testing the key generator directly.
module.exports.keyGenerator = keyGenerator;
const rateLimit = require('express-rate-limit');

module.exports = function createRateLimiter(config = {}) {
  const windowMs = config.windowMs || 60000; // 1 minute
  const maxRequests = config.maxRequests || 60;
  const maxPerHost = config.maxPerHost || 20;
  
  // Store for per-host limiting
  const hostCounts = new Map();
  
  return rateLimit({
    windowMs,
    max: maxRequests,
    message: 'Too many requests, please try again later',
    standardHeaders: true,
    legacyHeaders: false,
    
    // Custom key generator that includes host
    keyGenerator: (req) => {
      const host = req.body?.metadata?.host || 'unknown';
      const ip = req.ip;
      return `${ip}:${host}`;
    },
    
    // Custom handler to check per-host limits
    handler: (req, res, next, options) => {
      const host = req.body?.metadata?.host || 'unknown';
      const count = hostCounts.get(host) || 0;
      
      if (count >= maxPerHost) {
        return res.status(429).json({
          error: 'Rate limit exceeded for host',
          host,
          limit: maxPerHost,
          windowMs
        });
      }
      
      // Update host count
      hostCounts.set(host, count + 1);
      
      // Clean up old entries periodically
      setTimeout(() => {
        const newCount = hostCounts.get(host) - 1;
        if (newCount <= 0) {
          hostCounts.delete(host);
        } else {
          hostCounts.set(host, newCount);
        }
      }, windowMs);
      
      res.status(options.statusCode).json({
        error: options.message,
        retryAfter: Math.round(options.windowMs / 1000)
      });
    }
  });
};
module.exports = function base64Middleware(req, res, next) {
  if (req.body && req.body.data) {
    try {
      // Decode base64 command data
      const buffer = Buffer.from(req.body.data, 'base64');
      req.decodedData = buffer.toString('utf-8');
      req.rawData = buffer;

      // Decode base64 stdin data (for content piped separately from command)
      if (req.body.stdin) {
        const stdinBuffer = Buffer.from(req.body.stdin, 'base64');
        req.stdinData = stdinBuffer.toString('utf-8');
        req.rawStdinData = stdinBuffer;
      }

      // Store metadata
      req.metadata = req.body.metadata || {};

      // Add timestamp if not present
      if (!req.metadata.timestamp) {
        req.metadata.timestamp = new Date().toISOString();
      }

    } catch (error) {
      return res.status(400).json({
        error: 'Invalid base64 data',
        details: error.message
      });
    }
  }

  next();
};
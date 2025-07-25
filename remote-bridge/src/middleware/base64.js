module.exports = function base64Middleware(req, res, next) {
  if (req.body && req.body.data) {
    try {
      // Decode base64 data
      const buffer = Buffer.from(req.body.data, 'base64');
      req.decodedData = buffer.toString('utf-8');
      req.rawData = buffer;
      
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
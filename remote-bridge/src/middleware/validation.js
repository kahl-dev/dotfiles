module.exports = function validationMiddleware(req, res, next) {
  // Skip validation for GET requests
  if (req.method === 'GET') {
    return next();
  }
  
  // Validate required fields
  if (!req.body) {
    return res.status(400).json({ error: 'Request body is required' });
  }
  
  if (!req.body.data && req.path !== '/health') {
    return res.status(400).json({ error: 'Data field is required' });
  }
  
  // Validate metadata
  if (req.body.metadata) {
    const { host, session, user } = req.body.metadata;
    
    if (host && typeof host !== 'string') {
      return res.status(400).json({ error: 'Invalid host in metadata' });
    }
    
    if (session && typeof session !== 'string') {
      return res.status(400).json({ error: 'Invalid session in metadata' });
    }
    
    if (user && typeof user !== 'string') {
      return res.status(400).json({ error: 'Invalid user in metadata' });
    }
  }
  
  // Validate specific endpoints
  switch (req.path) {
    case '/browser':
      // URL will be validated in the handler after base64 decode
      break;
      
    case '/notify':
      if (req.body.options) {
        const { type, title, sound } = req.body.options;
        
        if (type && typeof type !== 'string') {
          return res.status(400).json({ error: 'Invalid notification type' });
        }
        
        if (title && typeof title !== 'string') {
          return res.status(400).json({ error: 'Invalid notification title' });
        }
        
        if (sound && typeof sound !== 'string') {
          return res.status(400).json({ error: 'Invalid notification sound' });
        }
      }
      break;
  }
  
  next();
};
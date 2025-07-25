const clipboardy = require('clipboardy').default || require('clipboardy');

module.exports = {
  name: 'clipboard',
  version: '1.0.0',
  
  endpoints: [
    {
      path: '/clipboard',
      method: 'POST',
      handler: async function(req, res) {
        try {
          const data = req.decodedData;
          const metadata = req.metadata;
          
          // Set clipboard
          await clipboardy.write(data);
          
          // Store result for after hooks
          res.result = { 
            success: true, 
            length: data.length,
            type: req.body.options?.type || 'text'
          };
          
          // Log
          this.server.logger.info('Clipboard updated', {
            host: metadata.host,
            session: metadata.session,
            length: data.length,
            type: res.result.type
          });
          
          res.json(res.result);
          
        } catch (error) {
          throw new Error(`Failed to set clipboard: ${error.message}`);
        }
      }
    }
  ],
  
  initialize: function(server) {
    this.server = server;
  }
};
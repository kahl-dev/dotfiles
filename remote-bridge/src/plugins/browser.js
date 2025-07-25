const open = require('open').default || require('open');

module.exports = {
  name: 'browser',
  version: '1.0.0',
  
  endpoints: [
    {
      path: '/browser',
      method: 'POST',
      handler: async function(req, res) {
        try {
          const url = req.decodedData;
          const metadata = req.metadata;
          const options = req.body.options || {};
          
          // Validate URL
          if (!options.noValidate) {
            try {
              new URL(url);
            } catch (error) {
              throw new Error(`Invalid URL: ${error.message}`);
            }
          }
          
          // Open URL
          await open(url, {
            wait: false,
            ...(options.app && { app: { name: options.app } })
          });
          
          // Store result
          res.result = {
            success: true,
            url,
            validated: !options.noValidate
          };
          
          // Log
          this.server.logger.info('URL opened', {
            host: metadata.host,
            session: metadata.session,
            url,
            app: options.app || 'default'
          });
          
          res.json(res.result);
          
        } catch (error) {
          throw new Error(`Failed to open URL: ${error.message}`);
        }
      }
    }
  ],
  
  initialize: function(server) {
    this.server = server;
  }
};
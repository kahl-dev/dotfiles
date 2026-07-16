const { execFile, spawn } = require('child_process');
const path = require('path');

/**
 * Escape a value for embedding inside an AppleScript double-quoted string
 * literal. Backslash first, so a literal backslash in the input doesn't
 * collide with the quote-escaping pass that follows it.
 */
function escapeAppleScriptString(value) {
  return String(value).replace(/\\/g, '\\\\').replace(/"/g, '\\"');
}

/**
 * Build the `display notification` AppleScript source for the osascript
 * fallback path.
 */
function buildNotifyScript({ message, title, sound }) {
  const soundName = sound || 'Pop';
  return `display notification "${escapeAppleScriptString(message)}" with title "${escapeAppleScriptString(title)}" sound name "${escapeAppleScriptString(soundName)}"`;
}

/**
 * Build the argv for `osascript -e <script>`. Kept separate from the script
 * builder so callers invoke osascript via execFile's args array — never a
 * shell-interpolated command string — which is what closes the injection
 * hole (a `'` in message/title/sound can no longer break out of shell
 * quoting, since there is no shell in the loop).
 */
function buildOsascriptArgs({ message, title, sound }) {
  return ['-e', buildNotifyScript({ message, title, sound })];
}

module.exports = {
  name: 'notify',
  version: '1.0.0',

  // Exported for unit testing the osascript argv builder directly.
  buildOsascriptArgs,

  endpoints: [
    {
      path: '/notify',
      method: 'POST',
      handler: async function(req, res) {
        try {
          const message = req.decodedData;
          const metadata = req.metadata;
          const options = req.body.options || {};

          if (!metadata || typeof metadata.session !== 'string') {
            return res.status(400).json({ error: 'metadata.session is required' });
          }

          // Find matching rule
          const rule = this.findMatchingRule(options.type);
          
          // Build notification
          const notification = {
            title: options.title || `Remote: ${metadata.host}`,
            message,
            sound: options.sound || rule?.sound || this.config.defaultSound,
            subtitle: options.subtitle || (metadata.session.startsWith('%') ? metadata.host : `Session: ${metadata.session}`),
            timeout: options.timeout || 10,
          };
          
          // Add custom data if provided
          if (options.data) {
            try {
              notification.data = Buffer.from(options.data, 'base64').toString('utf-8');
            } catch {
              notification.data = options.data;
            }
          }
          
          // Send notification using terminal-notifier
          await this.sendNotification(notification);
          
          // Store result
          res.result = {
            success: true,
            type: options.type,
            rule: rule?.type
          };
          
          // Log
          this.server.logger.info('Notification sent', {
            host: metadata.host,
            session: metadata.session,
            type: options.type,
            title: notification.title,
            sound: notification.sound
          });
          
          res.json(res.result);
          
        } catch (error) {
          throw new Error(`Failed to send notification: ${error.message}`);
        }
      }
    }
  ],
  
  initialize: function(server) {
    this.server = server;
    this.config = server.config.notifications || {};
  },
  
  findMatchingRule: function(type) {
    if (!type || !this.config.rules) return null;
    
    return this.config.rules.find(rule => {
      if (rule.type === type) return true;
      if (rule.type.includes('*')) {
        const pattern = new RegExp('^' + rule.type.replace('*', '.*') + '$');
        return pattern.test(type);
      }
      return false;
    });
  },
  
  sendNotification: function(notification) {
    return new Promise((resolve, reject) => {
      // Build terminal-notifier arguments
      const args = [
        '-title', notification.title,
        '-message', notification.message
      ];
      
      if (notification.subtitle) {
        args.push('-subtitle', notification.subtitle);
      }
      
      if (notification.sound) {
        args.push('-sound', notification.sound);
      }
      
      // Debug log
      this.server.logger.info('Terminal-notifier args', { args });
      
      // Use spawn with full path for better handling
      const child = spawn('/opt/homebrew/bin/terminal-notifier', args);
      
      let stderr = '';
      child.stderr.on('data', (data) => {
        stderr += data.toString();
      });
      
      child.on('error', (error) => {
        // Fallback to osascript if terminal-notifier fails. execFile passes
        // the script as a single argv element — no shell parses it, so
        // quote characters in the message/title/sound can't break out.
        const osascriptArgs = buildOsascriptArgs(notification);
        execFile('osascript', osascriptArgs, (osError) => {
          if (osError) {
            reject(new Error(`Notification failed: ${error.message}`));
          } else {
            resolve({ method: 'osascript' });
          }
        });
      });
      
      child.on('close', (code) => {
        if (code !== 0) {
          reject(new Error(`terminal-notifier exited with code ${code}: ${stderr}`));
        } else {
          resolve({ method: 'terminal-notifier' });
        }
      });
    });
  }
};
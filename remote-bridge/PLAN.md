# Remote Bridge - Implementation Plan

A bidirectional communication system for remote SSH sessions to interact with the local macOS system.

## Overview

Remote Bridge enables:
- 📋 Clipboard synchronization (remote → local)
- 🌐 Opening URLs in local browser from remote
- 🔔 Notifications with custom sounds and rules
- 🔌 Extensible plugin system
- 📊 Comprehensive logging and monitoring

## Architecture

### Core Components

1. **Local Service** (Node.js/Express)
   - Runs on port 8377
   - RESTful API with base64 encoded payloads
   - Plugin system for extensibility
   - Rate limiting and security

2. **Remote CLI Tools**
   - `rclip` - Send to clipboard
   - `ropen` - Open URL in browser
   - `rnotify` - Send notifications
   - Automatic tunnel detection with OSC52 fallback

3. **SSH Integration**
   - Reverse tunnel configuration
   - Automatic setup via SSH config
   - Multi-session support

## Directory Structure

```
~/.dotfiles/remote-bridge/
├── src/
│   ├── server.js              # Main Express server
│   ├── plugins/               # Core plugins
│   │   ├── clipboard.js       # Clipboard handling
│   │   ├── browser.js         # URL opening
│   │   └── notify.js          # Notification system
│   ├── utils/
│   │   ├── base64.js         # Encoding/decoding
│   │   ├── logger.js         # Logging utilities
│   │   └── plugin-loader.js  # Dynamic plugin loading
│   └── middleware/
│       ├── rate-limit.js     # Rate limiting
│       ├── validation.js     # Request validation
│       └── base64.js         # Base64 middleware
├── bin/
│   ├── remote-bridge         # Service control
│   ├── rclip                # Clipboard CLI
│   ├── ropen                # Browser CLI
│   └── rnotify              # Notification CLI
├── config/
│   └── default.yaml         # Default configuration
├── package.json             # Dependencies
└── README.md               # User documentation
```

## API Design

### Endpoints

```
POST /clipboard   - Set clipboard content
POST /browser     - Open URL in browser
POST /notify      - Send notification
GET  /health      - Health check
GET  /history     - View activity log
```

### Request Format

All requests use base64 encoded data:

```json
{
  "data": "base64_encoded_content",
  "metadata": {
    "host": "hostname",
    "session": "tmux-pane-id",
    "user": "username",
    "timestamp": "ISO-8601"
  },
  "options": {
    // Endpoint-specific options
  }
}
```

## Configuration

### User Configuration (`~/.config/remote-bridge/config.yaml`)

```yaml
service:
  port: 8377
  logLevel: "info"
  
notifications:
  rules:
    - type: "claude-hook"
      requiresInteraction: true
      sound: "Glass"
      priority: "high"
    - type: "build-complete"
      sound: "Ping"
      priority: "normal"
  defaultSound: "Pop"
  
rateLimit:
  windowMs: 60000
  maxRequests: 60
  maxPerHost: 20
  
logging:
  file: "~/.local/share/remote-bridge/activity.log"
  maxSize: "10MB"
  maxFiles: 5
  
plugins:
  enabled:
    - "claude-handler"
    - "screenshot-processor"
```

### SSH Configuration

Add to `~/.ssh/config`:

```
Host *
    RemoteForward 8377 localhost:8377
    SetEnv REMOTE_BRIDGE_PORT=8377
```

## Plugin System

### Plugin Structure

```javascript
module.exports = {
  name: 'plugin-name',
  version: '1.0.0',
  
  // Register custom endpoints
  endpoints: [
    {
      path: '/custom/endpoint',
      method: 'POST',
      handler: async (req, res) => {
        // Handle request
      }
    }
  ],
  
  // Hook into existing functionality
  hooks: {
    beforeClipboard: async (data, metadata) => data,
    afterClipboard: async (data, metadata, result) => {},
    beforeNotification: async (data, metadata) => data,
    afterNotification: async (data, metadata, result) => {}
  },
  
  // Custom notification types
  notificationHandlers: {
    'custom-type': async (data, config) => {
      // Handle notification
    }
  }
};
```

### Example: Claude Hook Handler

```javascript
// ~/.config/remote-bridge/plugins/claude-handler.js
module.exports = {
  name: 'claude-handler',
  
  hooks: {
    beforeNotification: async (data, metadata) => {
      if (data.type === 'claude-hook') {
        // Enhance notification
        data.title = `Claude - ${metadata.host}`;
        data.subtitle = `Session: ${metadata.session}`;
        
        // Log to separate file
        await this.logClaudeEvent(data, metadata);
        
        // Determine sound based on urgency
        if (data.requiresInteraction) {
          data.sound = 'Sosumi';
        }
      }
      return data;
    }
  },
  
  logClaudeEvent: async function(data, metadata) {
    // Custom logging logic
  }
};
```

## Service Management

### LaunchAgent (`~/Library/LaunchAgents/com.kahl-dev.remote-bridge.plist`)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.kahl-dev.remote-bridge</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/kahl-dev/.dotfiles/remote-bridge/bin/remote-bridge</string>
        <string>start</string>
        <string>--daemon</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/kahl-dev/.local/share/remote-bridge/service.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/kahl-dev/.local/share/remote-bridge/service.error.log</string>
</dict>
</plist>
```

### Management Commands

```bash
# Service control
remote-bridge start          # Start service
remote-bridge stop           # Stop service
remote-bridge restart        # Restart service
remote-bridge status         # Check status
remote-bridge logs           # View logs

# Plugin management
remote-bridge plugin list    # List plugins
remote-bridge plugin enable  # Enable plugin
remote-bridge plugin disable # Disable plugin

# Development
remote-bridge dev           # Run in foreground
remote-bridge test          # Run tests
```

## CLI Tools

### rclip - Clipboard Tool

```bash
# Basic usage
echo "Hello" | rclip

# With type hint
cat image.png | rclip --type image

# From file
rclip < file.txt

# With custom metadata
echo "data" | rclip --tag "important"
```

### ropen - Browser Tool

```bash
# Open URL
ropen "https://example.com"

# With validation disabled (for local URLs)
ropen "http://localhost:3000" --no-validate

# Open multiple URLs
echo -e "url1\nurl2" | ropen --batch
```

### rnotify - Notification Tool

```bash
# Simple notification
rnotify "Build complete"

# With title and type
rnotify "Tests failed" --title "CI Status" --type "build-error"

# With JSON data
echo '{"errors": 5}' | rnotify "Build failed" --json

# Claude hook example
rnotify "Permission denied" \
  --type "claude-hook" \
  --data '{"tool": "bash", "command": "rm -rf"}'
```

## Installation

### Via Makefile

```bash
# Add to Makefile
install-remote-bridge:
	@echo "Installing Remote Bridge..."
	cd remote-bridge && pnpm install
	./remote-bridge/bin/remote-bridge install
```

### Manual Installation

```bash
# Install dependencies
cd ~/.dotfiles/remote-bridge
pnpm install

# Install service
./bin/remote-bridge install

# Add to PATH (in .zshrc)
export PATH="$HOME/.dotfiles/remote-bridge/bin:$PATH"
```

### Dotbot Integration

```yaml
# meta/ingredients/remote-bridge.yaml
- link:
    ~/.config/remote-bridge: .config/remote-bridge
    ~/bin/rclip: remote-bridge/bin/rclip
    ~/bin/ropen: remote-bridge/bin/ropen
    ~/bin/rnotify: remote-bridge/bin/rnotify
    ~/bin/remote-bridge: remote-bridge/bin/remote-bridge

- shell:
    - [cd remote-bridge && pnpm install, Installing Remote Bridge dependencies]
    - [remote-bridge install, Installing Remote Bridge service]
```

## Security Considerations

1. **Local Only**: Service only accepts connections from localhost
2. **Rate Limiting**: Per-host and global rate limits
3. **Validation**: All inputs validated and sanitized
4. **No Secrets**: No authentication tokens in transit
5. **SSH Tunnel**: All remote communication through SSH

## Performance Optimizations

1. **Connection Pooling**: Reuse HTTP connections
2. **Request Batching**: Queue and batch rapid requests
3. **Async Processing**: Non-blocking notification handling
4. **Log Rotation**: Automatic log file management
5. **Memory Management**: Plugin unloading when disabled

## Future Enhancements

- [ ] WebSocket support for real-time features
- [ ] File transfer support
- [ ] Bidirectional clipboard (local → remote)
- [ ] Integration with other services (Slack, Discord)
- [ ] Web UI for configuration and monitoring
- [ ] Encryption for sensitive data
- [ ] Multi-user support with authentication
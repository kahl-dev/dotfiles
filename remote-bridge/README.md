# Remote Bridge

A bidirectional communication system for remote SSH sessions to interact with your local macOS system.

## Features

- 📋 **Clipboard Sync**: Send text and images from remote to local clipboard
- 🌐 **URL Opening**: Open URLs in your local browser from remote sessions
- 🔔 **Smart Notifications**: Configurable notifications with sounds and rules
- 🔌 **Plugin System**: Extend functionality with custom JavaScript plugins
- 🔒 **Secure**: Only accessible through SSH reverse tunnels
- 📊 **Logging**: Comprehensive activity logging with rotation

## Quick Start

### Installation

```bash
# Install dependencies
cd ~/.dotfiles/remote-bridge
pnpm install

# Install the service
./bin/remote-bridge install

# Start the service
./bin/remote-bridge start

# Check status
./bin/remote-bridge status
```

### SSH Configuration

Add to your `~/.ssh/config`:

```
Host *
    RemoteForward 8377 localhost:8377
    SetEnv REMOTE_BRIDGE_PORT=8377
```

### Basic Usage

From any SSH session:

```bash
# Copy to clipboard
echo "Hello from remote" | rclip
cat file.txt | rclip

# Open URL
ropen "https://github.com"

# Send notification
rnotify "Build complete" --type build-success
```

## CLI Tools

### rclip - Clipboard Tool

```bash
# Basic usage
echo "text" | rclip

# Copy image
cat screenshot.png | rclip --type image

# With metadata tag
echo "important" | rclip --tag work
```

### ropen - Browser Tool

```bash
# Open single URL
ropen "https://example.com"

# Open in specific app
ropen --app "Firefox" "https://example.com"

# Open multiple URLs
ropen "https://github.com" "https://google.com"

# Skip validation for local URLs
ropen --no-validate "http://localhost:3000"
```

### rnotify - Notification Tool

```bash
# Simple notification
rnotify "Task complete"

# With title and type
rnotify "Tests passed" --title "CI Status" --type test-pass

# Claude hook example
rnotify "Permission denied" \
  --type claude-hook \
  --data '{"tool": "bash", "command": "rm -rf /"}'

# With custom sound
rnotify "Deploy complete" --sound Hero --type deployment
```

## Configuration

Configuration file: `~/.config/remote-bridge/config.yaml`

### Example Configuration

```yaml
service:
  port: 8377
  logLevel: info

notifications:
  rules:
    - type: "claude-hook"
      requiresInteraction: true
      sound: "Glass"
      priority: "high"
    
    - type: "build-*"
      sound: "Ping"
      priority: "normal"
  
  defaultSound: "Pop"

plugins:
  enabled: ["my-plugin"]
```

### Available Notification Sounds

Basso, Blow, Bottle, Frog, Funk, Glass, Hero, Morse, Ping, Pop, Purr, Sosumi, Submarine, Tink

## Plugin Development

Create plugins in `~/.config/remote-bridge/plugins/`:

```javascript
// ~/.config/remote-bridge/plugins/my-plugin.js
module.exports = {
  name: 'my-plugin',
  version: '1.0.0',
  
  // Add custom endpoints
  endpoints: [
    {
      path: '/custom/action',
      method: 'POST',
      handler: async (req, res) => {
        const data = req.decodedData;
        // Your logic here
        res.json({ success: true });
      }
    }
  ],
  
  // Hook into existing functionality
  hooks: {
    beforeClipboard: async (data, metadata) => {
      console.log(`Clipboard from ${metadata.host}`);
      return data;
    },
    
    afterNotification: async (data, metadata, result) => {
      // React to notifications
    }
  }
};
```

Enable in config:
```yaml
plugins:
  enabled: ["my-plugin"]
```

## Service Management

```bash
# Service control
remote-bridge start      # Start service
remote-bridge stop       # Stop service
remote-bridge restart    # Restart service
remote-bridge status     # Check status

# View logs
remote-bridge logs       # Last 50 lines
remote-bridge logs -f    # Follow logs
remote-bridge logs -n 100  # Last 100 lines

# Development
remote-bridge dev        # Run in foreground
remote-bridge test-tunnel  # Test SSH tunnel
```

## Troubleshooting

### Service not accessible

1. Check service status: `remote-bridge status`
2. Check logs: `remote-bridge logs`
3. Test tunnel: `remote-bridge test-tunnel`
4. Verify SSH config includes `RemoteForward 8377 localhost:8377`

### Commands not working

1. Check if tunnel is active: `curl http://localhost:8377/health`
2. Verify `REMOTE_BRIDGE_PORT` environment variable
3. Check service logs for errors
4. Fallback to OSC52 should work for clipboard

### Notifications not appearing

1. Check macOS notification permissions
2. Verify notification type matches config rules
3. Check logs for notification errors
4. Test with simple notification: `rnotify "Test"`

## Architecture

- **Local Service**: Node.js/Express server on port 8377
- **Communication**: Base64-encoded JSON over HTTP
- **Security**: Localhost-only binding + SSH tunnel
- **Extensibility**: JavaScript plugin system
- **Logging**: Winston with rotation

## License

MIT
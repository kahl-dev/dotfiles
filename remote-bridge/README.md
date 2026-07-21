# Remote Bridge

A bidirectional communication system for remote SSH sessions to interact with your local macOS system.

## Table of Contents

- [Features](#features)
- [Install](#install)
- [SSH Configuration](#ssh-configuration)
- [Authentication](#authentication)
- [Usage](#usage)
- [CLI Tools](#cli-tools)
- [Configuration](#configuration)
- [Plugin Development](#plugin-development)
- [Service Management](#service-management)
- [Troubleshooting](#troubleshooting)
- [Architecture](#architecture)
- [License](#license)

## Features

- 📋 **Clipboard Sync**: Send text and images from remote to local clipboard
- 🌐 **URL Opening**: Open URLs in your local browser from remote sessions
- 🔔 **Smart Notifications**: Configurable notifications with sounds and rules
- 🔌 **Plugin System**: Extend functionality with custom JavaScript plugins
- 🔒 **Secure**: Localhost-bound service, per-user Unix sockets, and mandatory Bearer-token auth on every request
- 📊 **Logging**: Comprehensive activity logging with rotation

## Install

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

## SSH Configuration

Opt each bridge-enabled host in with an SSH tag:

```sshconfig
Host myserver
    Tag remote-bridge
```

`sm myserver` detects the tag through `ssh -G`, starts autossh, and creates two sockets on the remote host:

- `~/.ssh/remote-bridge.sock` forwards to the Mac service at `localhost:8377`.
- `~/.ssh/agent-tunnel.sock` forwards to the Mac's `SSH_AUTH_SOCK`.

Do not add static `RemoteForward` entries. Plain SSH sessions would compete with the autossh tunnel for the same socket paths. `Tag` requires OpenSSH 9.2 or newer on the Mac.

## Authentication

Every request needs `Authorization: Bearer $REMOTE_BRIDGE_TOKEN` — `GET /health` is the only exempt route. The server fail-closes at startup if no token is configured. Clients resolve the token env-first, then from atuin's synced dotfiles vars. Set it once:

```bash
atuin dotfiles var set REMOTE_BRIDGE_TOKEN "$(openssl rand -hex 32)"
```

## Usage

From a bridge-enabled `sm` session:

```bash
# Copy to clipboard
echo "Hello from remote" | rclip
cat file.txt | rclip

# Open URL
ropen "https://github.com"

# Send notification
rnotify "Build complete"
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
```

### rnotify - Notification Tool

```bash
# Simple notification
rnotify "Task complete"

# With title and type
rnotify "Tests passed" --title "CI Status"

# Claude hook example
rnotify "Permission denied" \
  --type claude-permission_prompt \
  --data '{"tool": "bash", "command": "rm -rf /"}'

# With custom sound
rnotify "Deploy complete" --sound Hero
```

### rtime - Time Tracking Tool

```bash
# Fetch specific dates
rtime fetch --dates 2026-03-25,2026-03-24

# Fetch last 7 days / today only
rtime fetch --week
rtime fetch --today

# Save JSONL files to a directory instead of stdout JSON
rtime fetch --today --output ~/time-tracking

# List available dates
rtime dates
```

### robsidian - Obsidian CLI Wrapper

Local: execs the `obsidian` CLI directly. Remote: proxies the same command through Remote Bridge.

```bash
# Run any obsidian CLI command
robsidian vault
robsidian search query="daily notes" format=json

# Create/append a note inline
robsidian create path="notes/test.md" content="Hello"

# Create/append from stdin or a file — bypasses shell escaping issues
# (backticks, $variables, unicode, etc.)
cat research.md | robsidian create path="notes/research.md" --stdin
robsidian append path="notes/log.md" --content-file=/tmp/entry.md
```

### PATH Shims

Drop-in replacements in `bin/` (dotfiles root, ahead of `/usr/bin` on `PATH`) so tools that shell out to Linux-native commands transparently hit the bridge instead:

- `xclip`, `wl-copy` — route to `rclip`, so anything that execs them (e.g. lazygit) reaches the local clipboard
- `xdg-open` — routes `http(s)` opens through `ropen` and rejects other schemes; paired with `BROWSER=ropen` (exported non-macOS in `.zshenv`) so nvim's `gx` and friends reach the Mac's browser

## Configuration

Configuration file: `~/.config/remote-bridge/config.yaml`

### Example Configuration

```yaml
service:
  port: 8377
  logLevel: info

notifications:
  rules:
    - type: "claude-idle_prompt"
      sound: "Glass"
    - type: "claude-permission_prompt"
      sound: "Ping"
    - type: "error"
      sound: "Basso"
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
remote-bridge test-tunnel  # Test the local service endpoint
```

## Troubleshooting

### Service not accessible

1. On the Mac, check the service: `remote-bridge status`.
2. On the Mac, check logs: `remote-bridge logs`.
3. Confirm the host is tagged: `ssh -G <host> | grep '^tag remote-bridge$'`.
4. Restart the tunnel: `sm-kill <host>`, then `sm <host>`.

### Commands not working

Run `rb-status` on the remote host. To probe the bridge directly:

```bash
curl -sf --unix-socket ~/.ssh/remote-bridge.sock http://localhost/health
SSH_AUTH_SOCK=~/.ssh/agent-tunnel.sock ssh-add -l
```

- **Socket absent**: Start a tagged host with `sm <host>` from the Mac.
- **Socket exists but is unresponsive**: Run `sm-kill <host>` and reconnect with `sm <host>`.
- **Tag missing**: Add `Tag remote-bridge` to the host block; do not add `RemoteForward`.
- **Clipboard only**: `rclip` can fall back to OSC52 in an interactive, non-tmux plain-SSH shell. It fails honestly in tmux and over mosh when the bridge is unavailable.

### Notifications not appearing

1. Check macOS notification permissions
2. Verify notification type matches config rules
3. Check logs for notification errors
4. Test with simple notification: `rnotify "Test"`

## Architecture

- **Local Service**: Node.js/Express server on port 8377
- **Remote transport**: autossh forwards `~/.ssh/remote-bridge.sock` and `~/.ssh/agent-tunnel.sock`
- **Per-user isolation**: Socket paths live below each remote user's home directory
- **Communication**: Base64-encoded JSON over HTTP
- **Security**: Localhost-only binding + SSH Unix sockets + mandatory Bearer-token auth (server fail-closes without `REMOTE_BRIDGE_TOKEN`; `GET /health` exempt)
- **Extensibility**: JavaScript plugin system
- **Logging**: Winston with rotation

## License

MIT

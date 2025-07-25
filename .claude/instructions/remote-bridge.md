## Remote Bridge System

### Overview
Remote Bridge is a unified clipboard and URL handling system that works seamlessly across local and remote SSH sessions. It provides:
- **Clipboard sync** via `rclip` command
- **URL opening** via `ropen` command  
- **Notifications** via `rnotify` command
- Automatic fallback to OSC52 when tunnel unavailable
- Plugin system for extensibility

### Architecture
- **Local service**: Node.js/Express server on port 8377
- **SSH tunnel**: Uses reverse port forwarding (`RemoteForward 8377 localhost:8377`)
- **Protocol**: Base64-encoded JSON over HTTP
- **Security**: Localhost-only binding with rate limiting

### Setup

1. **Start the service on local machine**:
   ```bash
   remote-bridge start    # Start the service
   remote-bridge status   # Check if running
   remote-bridge logs -f  # View logs
   ```

2. **Configure SSH for automatic tunneling**:
   Add to `~/.ssh/config`:
   ```
   Host *
       RemoteForward 8377 localhost:8377
       SetEnv REMOTE_BRIDGE_PORT=8377
   ```

3. **Usage from anywhere**:
   ```bash
   # Clipboard operations
   echo "text" | rclip          # Copy text
   rclip "direct text"          # Copy without piping
   
   # Open URLs
   ropen "https://github.com"   # Opens in local browser
   
   # Send notifications
   rnotify "Build complete"     # Basic notification
   rnotify "Tests failed" --type error --sound Basso
   ```

### Integration Points

#### Neovim Clipboard
Configured in `.config/nvim/lua/config/options.lua`:
- Uses `rclip` for all clipboard operations
- Copy with `"+y` in normal/visual mode
- Paste with `"+p` or `"+P`
- Works identically on local and remote sessions

#### Tmux Clipboard
Configured in `tmux/tmux.conf`:
- Copy mode uses `rclip` for all copy operations
- `y` in copy mode sends selection to rclip
- No special OSC52 configuration needed

#### Shell Aliases
- `lia-copyurl` alias uses `rclip` for URL copying
- All clipboard operations unified through Remote Bridge

### How It Works

1. **Local session**: 
   - `rclip` → Remote Bridge → system clipboard (pbcopy)
   - `ropen` → Remote Bridge → system browser

2. **Remote session with tunnel**:
   - `rclip` → SSH tunnel → Remote Bridge → local clipboard
   - `ropen` → SSH tunnel → Remote Bridge → local browser

3. **Remote session without tunnel**:
   - `rclip` → Falls back to OSC52 escape sequences
   - `ropen` → Copies URL to clipboard via OSC52

### Troubleshooting

**Check if Remote Bridge is accessible**:
```bash
remote-bridge-status  # or rb-status
curl http://localhost:8377/health
```

**View logs**:
```bash
remote-bridge logs -f
# or directly:
tail -f ~/.config/remote-bridge/logs/remote-bridge-*.log
```

**Test clipboard**:
```bash
echo "test" | rclip
# Check system clipboard to verify
```

**Common issues**:
- Service not running: `remote-bridge start`
- SSH tunnel not configured: Check `RemoteForward` in SSH config
- Empty input: rclip shows warning and exits cleanly
- Nvim clipboard: Ensure `"+y` is used (not just `y`)

### Configuration

Main config file: `~/.config/remote-bridge/config.yaml`

Example for custom notification rules:
```yaml
notifications:
  rules:
    - type: "error"
      sound: "Basso"
      priority: "high"
    - type: "success"
      sound: "Glass"
  defaultSound: "Pop"
```
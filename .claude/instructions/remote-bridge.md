## Remote Bridge System

### Overview
Remote Bridge is a unified clipboard and URL handling system that works seamlessly across local and remote SSH sessions. It provides:
- **Clipboard sync** via `rclip` command
- **URL opening** via `ropen` command  
- **Notifications** via `rnotify` command
- `rclip` falls back to OSC52 for interactive non-tmux plain-SSH shells when the tunnel is unavailable; over mosh there is no fallback (mosh drops tmux's OSC52 unless it carries the `c;` selection-type option) — the bridge is the sole clipboard path
- Plugin system for extensibility

### Architecture
- **Local service**: Node.js/Express server on port 8377
- **SSH tunnel**: Reverse port forwarding with per-user port (prevents cross-talk on shared servers)
- **Per-user port**: Derived from remote username via `cksum` hash (range 49152–65534). Computed identically on local (`ssh -G`) and remote (`$USER`)
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
   Generate the per-user `RemoteForward` line:
   ```bash
   remote-bridge-ssh-config <hostname>   # Computes port from remote username
   ```
   Add the output to `~/.ssh/config` per host. Example:
   ```
   Host t3
       RemoteForward 60190 localhost:8377
   ```
   The remote port (60190) is unique to your username. The local destination is always 8377 (the bridge service).

3. **Set the auth token**:
   The server fail-closes at startup without a token — every request (except `GET /health`) requires `Authorization: Bearer $REMOTE_BRIDGE_TOKEN`. Clients resolve it env-first, then from atuin. Set it once:
   ```bash
   atuin dotfiles var set REMOTE_BRIDGE_TOKEN "$(openssl rand -hex 32)"
   ```

4. **Usage from anywhere**:
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
- Copy with `"+y` in normal/visual mode uses `rclip`
- The bridge is write-only by design (`rclip` has no paste counterpart), so `"+p` / `"+P` do NOT go through the bridge: locally it falls back to `pbpaste`, remotely there is no bridge paste path — use the terminal's own paste (bracketed paste, e.g. Cmd+V) instead

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
   - On non-macOS hosts, `.zshenv` exports `BROWSER=ropen` and `bin/xdg-open` routes `http(s)` opens through `ropen` (rejecting other schemes) — so nvim's `gx` or any other caller that shells out to `xdg-open` reaches the Mac's browser automatically

3. **Remote session without tunnel, plain SSH**:
   - `rclip` → Falls back to OSC52 escape sequences (interactive non-tmux shells only)
   - `ropen` → Copies URL to clipboard via OSC52
   - Over mosh (`sm`), there is no OSC52 fallback: mosh only relays OSC52 sequences carrying the `c;` selection-type option, and tmux doesn't emit it by default, so tmux's OSC52 is silently dropped (worse with nested tmux: remote-tmux → mosh → local-tmux → terminal). If the tunnel is down during a mosh session, `rclip` fails honestly (error, non-zero exit) instead of reporting false success.

### Troubleshooting

**Check if Remote Bridge is accessible**:
```bash
remote-bridge-status  # or rb-status
curl http://localhost:${REMOTE_BRIDGE_PORT}/health
```

**View logs**:
```bash
remote-bridge logs -f
# or directly:
tail -f ~/.local/share/remote-bridge/activity.log
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
- `robsidian` answers `Vault not found.` (exit code 0): Obsidian is running
  without a loaded vault (vault picker after reboot/background launch). Since
  obsidian plugin v1.3.0 the bridge and `robsidian` force-load the registered
  vault automatically; if it still fails, open the vault in Obsidian manually.
- Tunnel process alive but remote port dead (`curl localhost:$REMOTE_BRIDGE_PORT`
  fails on the server while `sm-status` looks fine): the RemoteForward failed at
  connect time — typically a stale sshd from before a reboot still held the
  port. `sm` now passes `ExitOnForwardFailure=yes` so autossh retries until the
  port frees; force a restart with `sm-kill <host>` and a new `sm <host>`.
  When diagnosing from the Mac, always use `ssh -o ClearAllForwardings=yes` —
  a plain `ssh` brings its own RemoteForward and masks the dead tunnel.

### Configuration

Main config file: `~/.config/remote-bridge/config.yaml`

Example for custom notification rules:
```yaml
notifications:
  rules:
    - type: "claude-idle_prompt"
      sound: "Glass"
    - type: "claude-permission_prompt"
      sound: "Ping"
    - type: "error"
      sound: "Basso"
  defaultSound: "Pop"
```
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
- **SSH tunnel**: `sm` owns two reverse Unix-socket forwards through autossh
- **Bridge socket**: `~/.ssh/remote-bridge.sock` forwards to the Mac service at `localhost:8377`
- **Agent socket**: `~/.ssh/agent-tunnel.sock` forwards to the Mac's `SSH_AUTH_SOCK`
- **Isolation**: Socket paths live below each remote user's home directory
- **Protocol**: Base64-encoded JSON over HTTP
- **Security**: Localhost-only binding, 0600 socket files, rate limiting, and Bearer-token auth

### Setup

1. **Start the service on local machine**:
   ```bash
   remote-bridge start    # Start the service
   remote-bridge status   # Check if running
   remote-bridge logs -f  # View logs
   ```

2. **Opt the host into automatic tunneling**:
   Add the side-effect-free tag to the host's SSH config block:
   ```sshconfig
   Host myserver
       Tag remote-bridge
   ```
   `sm` detects this through `ssh -G` and passes both forwards directly to autossh. Do not add static `RemoteForward` entries; plain SSH sessions would compete with autossh for the fixed socket paths. `Tag` requires OpenSSH 9.2 or newer on the Mac.

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
   - Bridge clients use `~/.ssh/remote-bridge.sock`
   - Git and other SSH clients use `~/.ssh/agent-tunnel.sock`
   - `rclip` → Unix socket → Remote Bridge → local clipboard
   - `ropen` → Unix socket → Remote Bridge → local browser
   - On non-macOS hosts, `.zshenv` exports `BROWSER=ropen` and `bin/xdg-open` routes `http(s)` opens through `ropen` (rejecting other schemes) — so nvim's `gx` or any other caller that shells out to `xdg-open` reaches the Mac's browser automatically

3. **Remote session without tunnel, plain SSH**:
   - `rclip` → Falls back to OSC52 escape sequences (interactive non-tmux shells only)
   - `ropen`, `rnotify`, `rtime`, and `robsidian` fail with an actionable socket error
   - Over mosh (`sm`), there is no OSC52 fallback: mosh only relays OSC52 sequences carrying the `c;` selection-type option, and tmux doesn't emit it by default, so tmux's OSC52 is silently dropped (worse with nested tmux: remote-tmux → mosh → local-tmux → terminal). If the tunnel is down during a mosh session, `rclip` fails honestly (error, non-zero exit) instead of reporting false success.

### Troubleshooting

**Check if Remote Bridge is accessible**:
```bash
remote-bridge-status  # or rb-status
curl -sf --unix-socket ~/.ssh/remote-bridge.sock http://localhost/health
SSH_AUTH_SOCK=~/.ssh/agent-tunnel.sock ssh-add -l
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
- Tag missing: `ssh -G <host> | grep '^tag remote-bridge$'` must match on the Mac. Add `Tag remote-bridge` to the host block if it does not.
- Tunnel down: Run `sm-kill <host>`, then reconnect with `sm <host>`.
- Socket absent: `rb-status` names the missing path. Start the tunnel from the Mac.
- Socket exists but is unresponsive: The tunnel is stale. `sm-kill <host>` followed by `sm <host>` removes and recreates both socket forwards.
- Empty input: rclip shows warning and exits cleanly
- Nvim clipboard: Ensure `"+y` is used (not just `y`)
- `robsidian` answers `Vault not found.` (exit code 0): Obsidian is running
  without a loaded vault (vault picker after reboot/background launch). Since
  obsidian plugin v1.3.0 the bridge and `robsidian` force-load the registered
  vault automatically; if it still fails, open the vault in Obsidian manually.
- Tunnel process alive but bridge health fails: `sm` rejects unhealthy reuse,
  kills the old autossh process, removes stale sockets through
  `bin/sm-ssh-wrapper`, and starts a fresh tunnel. Diagnose from the Mac with
  `ssh -o ClearAllForwardings=yes <host> ...` so the diagnostic connection
  cannot create competing forwards.

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

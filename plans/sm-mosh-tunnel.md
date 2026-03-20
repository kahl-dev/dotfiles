# Plan: sm (ssh-mosh) — Mosh with Auto Remote Bridge Tunnel

> Source: Design session (grill-me) 2026-03-20

## Architectural decisions

Durable decisions that apply across all phases:

- **Command**: `sm` — separate command, does NOT wrap/alias `mosh`
- **File**: `zsh/config/mosh.zsh` (new file, sourced after `remote-bridge.zsh` in `.zshrc`)
- **Detection**: `ssh -G <host>` to resolve effective SSH config; anchored regex for `remoteforward` matching port via `REMOTE_BRIDGE_PORT` env var
- **Port source**: Parsed from `ssh -G` output via `REMOTE_BRIDGE_PORT` (default 8377) — adapts if port changes
- **Tunnel tool**: `autossh -M 0 -f -T` with `tail -f /dev/null` (creates session channel for SSH agent forwarding), overridden keepalives (`ServerAliveInterval=10`, `ServerAliveCountMax=2`, `ExitOnForwardFailure=yes`) — no explicit `-R` flag, SSH config's RemoteForward is picked up automatically
- **Why `-T` + command, not `-N`**: `-N` prevents session channel creation, which disables SSH agent forwarding. Agent forwarding is needed so `prefix + R` in remote tmux can find a working agent socket for git operations
- **Tunnel verification**: `sleep 1` + PID alive check after `autossh -f` (which always returns 0 due to GATETIME=0)
- **Session state**: `/tmp/sm-<host>/` directory with one marker file per session (named by PID)
- **Tunnel PID**: `AUTOSSH_PIDFILE=/tmp/sm-<host>.pid`
- **Stale cleanup**: On each `sm` invocation, prune marker files whose PID no longer exists
- **Hostname validation**: `sm-kill` validates input against `^[a-zA-Z0-9._-]+$` to prevent path traversal
- **Dependency**: `autossh` via Homebrew (hard requirement, added to Brewfile)
- **Completion**: `compdef sm=ssh`
- **Output**: Brief one-liner on tunnel start/reuse, silent otherwise (errors to stderr)
- **Failure mode**: Hard fail — if tunnel fails to start, `sm` exits without launching mosh
- **Scope**: Mosh only — SSH connections use native RemoteForward from SSH config

---

## Phase 1: Core `sm` command

**User stories**: As a user, I can type `sm myserver` and get a mosh session with an autossh tunnel automatically started if the host has RemoteForward 8377 configured.

### What to build

The `sm` function in `zsh/config/mosh.zsh`. On invocation:

1. Extract the hostname from arguments (mosh argument parser handling `--ssh`, `--client`, `-p`, `--` etc.)
2. Run `ssh -G <host>` and check if output contains a `remoteforward` line with the bridge port
3. If RemoteForward detected: start `autossh -M 0 -f -T` with `tail -f /dev/null` and overridden keepalive options
4. Verify tunnel started (sleep 1 + PID check). Fail hard if tunnel didn't establish.
5. Launch `mosh <all-original-args>` (transparent passthrough)
6. On mosh exit: clean up session marker, kill tunnel if last session

### Acceptance criteria

- [x] `sm myserver` detects RemoteForward from SSH config and starts autossh tunnel before mosh
- [x] `sm plainserver` (no RemoteForward) launches plain mosh without tunnel (no autossh dependency needed)
- [x] All mosh arguments pass through unchanged (e.g. `sm --ssh="ssh -p 2222" myserver`, `sm --client /path myserver`)
- [x] Tunnel uses overridden keepalives (10s interval, 2 max count)
- [x] Port detected from `ssh -G` output via REMOTE_BRIDGE_PORT
- [x] Brief output when tunnel starts (e.g. "tunnel: started (8377)")
- [x] Errors print to stderr (e.g. autossh not found, tunnel failed to start)
- [x] SSH agent forwarding works via session channel (`-T` + `tail -f /dev/null`)

---

## Phase 2: Multi-session tracking + cleanup

**User stories**: As a user, I can open multiple `sm` sessions to the same host. The tunnel stays alive until the last session exits. Stale state from crashed sessions is cleaned up automatically.

### What to build

Directory-based session tracking layered onto the Phase 1 function:

1. On tunnel start: create `/tmp/sm-<host>/` directory
2. On each `sm` invocation: create marker file `/tmp/sm-<host>/$$` (current shell PID)
3. Before creating marker: scan existing markers, remove any whose PID is no longer running (stale cleanup)
4. If tunnel PID file exists but process is dead: clean up and start fresh tunnel
5. If tunnel already running and healthy: reuse it (print "tunnel: reusing (port)")
6. On mosh exit: remove own marker file. If no markers remain, kill tunnel and clean up PID file + directory

### Acceptance criteria

- [x] Opening 3 sessions creates 3 marker files, tunnel starts once
- [x] Closing 2 of 3 sessions leaves tunnel running
- [x] Closing last session kills tunnel and cleans up `/tmp/sm-<host>/` entirely
- [x] If mosh crashed previously (stale marker with dead PID), marker is pruned on next `sm` invocation
- [x] If autossh died but markers exist, tunnel is restarted transparently
- [x] Output distinguishes "tunnel: started" vs "tunnel: reusing"

---

## Phase 3: Management commands + polish

**User stories**: As a user, I can inspect active tunnels with `sm-status` and force-kill them with `sm-kill`. Tab completion works for hostnames. autossh is part of the standard Brewfile.

### What to build

1. **`sm-status`**: List all active tunnels by scanning `/tmp/sm-*.pid` files. For each: show host, tunnel PID, port, and active session count (from marker directory). Prune stale entries during listing. Minimal output style.
2. **`sm-kill [host]`**: Kill tunnel for a specific host (or all if no argument). Hostname validated against `^[a-zA-Z0-9._-]+$`. Remove PID file, marker directory.
3. **`compdef sm=ssh`**: Tab completion for hostnames.
4. **Brewfile**: Add `brew "autossh"` to `brew/osx/.Brewfile`.
5. **CLAUDE.md**: Document `mosh.zsh` in shell config table and `sm` commands.

### Acceptance criteria

- [x] `sm-status` lists all active tunnels with host, PID, port, session count
- [x] `sm-status` shows "no active tunnels" when none exist
- [x] `sm-kill myserver` kills tunnel and cleans up all state for that host
- [x] `sm-kill` with no argument kills all active tunnels
- [x] `sm-kill ../../etc` rejected by hostname validation
- [x] `sm <TAB>` completes SSH hostnames
- [x] `autossh` is in Brewfile
- [x] `sm-status` prunes stale PIDs during listing

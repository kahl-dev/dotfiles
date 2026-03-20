# Plan: sm (ssh-mosh) — Mosh with Auto Remote Bridge Tunnel

> Source: Design session (grill-me) 2026-03-20

## Architectural decisions

Durable decisions that apply across all phases:

- **Command**: `sm` — separate command, does NOT wrap/alias `mosh`
- **File**: `zsh/config/mosh.zsh` (new file, auto-sourced by zsh config loader)
- **Detection**: `ssh -G <host>` to resolve effective SSH config; grep for `remoteforward` containing port 8377
- **Port source**: Parsed from `ssh -G` output, not hardcoded — adapts if port changes in SSH config
- **Tunnel tool**: `autossh -M 0 -f -N` with overridden keepalives (`ServerAliveInterval=10`, `ServerAliveCountMax=2`, `ExitOnForwardFailure=yes`) — no explicit `-R` flag, SSH config's RemoteForward is picked up automatically
- **Session state**: `/tmp/sm-<host>/` directory with one marker file per session (named by PID)
- **Tunnel PID**: `AUTOSSH_PIDFILE=/tmp/sm-<host>.pid`
- **Stale cleanup**: On each `sm` invocation, prune marker files whose PID no longer exists
- **Dependency**: `autossh` via Homebrew (hard requirement, added to Brewfile)
- **Completion**: `compdef sm=ssh`
- **Output**: Brief one-liner on tunnel start/reuse, silent otherwise (errors to stderr)
- **Scope**: Mosh only — SSH connections use native RemoteForward from SSH config

---

## Phase 1: Core `sm` command

**User stories**: As a user, I can type `sm myserver` and get a mosh session with an autossh tunnel automatically started if the host has RemoteForward 8377 configured.

### What to build

The `sm` function in `zsh/config/mosh.zsh`. On invocation:

1. Extract the hostname from arguments (first non-flag argument, same heuristic mosh uses)
2. Run `ssh -G <host>` and check if output contains a `remoteforward` line with port 8377
3. If RemoteForward detected: start `autossh -M 0 -f -N -R <parsed-port>:localhost:<parsed-port>` with overridden keepalive options
4. Launch `mosh <all-original-args>` (transparent passthrough)
5. No cleanup yet — tunnel persists after mosh exits

This phase proves the detection + tunnel + mosh pipeline works end-to-end.

### Acceptance criteria

- [ ] `sm myserver` detects RemoteForward from SSH config and starts autossh tunnel before mosh
- [ ] `sm plainserver` (no RemoteForward) launches plain mosh without tunnel
- [ ] All mosh arguments pass through unchanged (e.g. `sm --ssh="ssh -p 2222" myserver`)
- [ ] Tunnel uses overridden keepalives (10s interval, 2 max count)
- [ ] Port is parsed from `ssh -G` output, not hardcoded
- [ ] Brief output when tunnel starts (e.g. "tunnel: started (8377)")
- [ ] Errors print to stderr (e.g. autossh not found)

---

## Phase 2: Multi-session tracking + cleanup

**User stories**: As a user, I can open multiple `sm` sessions to the same host. The tunnel stays alive until the last session exits. Stale state from crashed sessions is cleaned up automatically.

### What to build

Directory-based session tracking layered onto the Phase 1 function:

1. On tunnel start: create `/tmp/autossh-<host>/` directory
2. On each `sm` invocation: create marker file `/tmp/autossh-<host>/$$` (current shell PID)
3. Before creating marker: scan existing markers, remove any whose PID is no longer running (stale cleanup)
4. If tunnel PID file exists but process is dead: clean up and start fresh tunnel
5. If tunnel already running and healthy: reuse it (print "tunnel: reusing existing")
6. On mosh exit: remove own marker file. If no markers remain, kill tunnel and clean up PID file + directory

### Acceptance criteria

- [ ] Opening 3 sessions creates 3 marker files, tunnel starts once
- [ ] Closing 2 of 3 sessions leaves tunnel running
- [ ] Closing last session kills tunnel and cleans up `/tmp/autossh-<host>/` entirely
- [ ] If mosh crashed previously (stale marker with dead PID), marker is pruned on next `sm` invocation
- [ ] If autossh died but markers exist, tunnel is restarted transparently
- [ ] Output distinguishes "tunnel: started" vs "tunnel: reusing existing"

---

## Phase 3: Management commands + polish

**User stories**: As a user, I can inspect active tunnels with `sm-status` and force-kill them with `sm-kill`. Tab completion works for hostnames. autossh is part of the standard Brewfile.

### What to build

1. **`sm-status`**: List all active tunnels by scanning `/tmp/autossh-*.pid` files. For each: show host, tunnel PID, port, and active session count (from marker directory). Prune stale entries during listing.
2. **`sm-kill [host]`**: Kill tunnel for a specific host (or all if no argument). Remove PID file, marker directory. Confirm action.
3. **`compdef sm=ssh`**: Tab completion for hostnames.
4. **Brewfile**: Add `brew "autossh"` to `brew/osx/.Brewfile`.

### Acceptance criteria

- [ ] `sm-status` lists all active tunnels with host, PID, port, session count
- [ ] `sm-status` shows "no active tunnels" when none exist
- [ ] `sm-kill myserver` kills tunnel and cleans up all state for that host
- [ ] `sm-kill` with no argument lists active tunnels and prompts (or kills all)
- [ ] `sm <TAB>` completes SSH hostnames
- [ ] `autossh` is in Brewfile
- [ ] `sm-status` prunes stale PIDs during listing

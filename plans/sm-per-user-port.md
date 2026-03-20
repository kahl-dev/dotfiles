# Plan: Per-User Remote Bridge Port

> Source PRD: Design session (grill-me) 2026-03-20 — shared server port conflict resolution

## Architectural decisions

Durable decisions that apply across all phases:

- **Port formula**: `$(( 49152 + $(printf '%s' "$USER" | cksum | cut -d' ' -f1) % 16383 ))` — deterministic, POSIX `cksum`, range 49152–65534 (dynamic/private ports)
- **Local vs remote**: Local Mac always uses port 8377 (service listener). Remote SSH sessions compute per-user port from `$USER`
- **Detection**: `remote-bridge.zsh` uses `$SSH_CLIENT` to distinguish local from remote
- **SSH config**: Per-user port hardcoded in `RemoteForward` per host (one-time setup via helper)
- **sm detection**: Reads ANY `RemoteForward` from `ssh -G` output — no hardcoded port in sm
- **No ExitOnForwardFailure**: autossh connects regardless of port conflicts (same user's sessions share safely)
- **ClearAllForwardings**: mosh bootstrap SSH disables all forwards (autossh owns the tunnel)
- **Username source**: `ssh -G host` resolves remote username (handles local ≠ remote user)
- **No remote system changes**: Only dotfiles change. No sudo, no sshd config

---

## Phase 1: Per-user port formula in remote-bridge.zsh

**User stories**: As a developer on a shared server, my Remote Bridge port is unique to my username, preventing cross-talk with other developers.

### What to build

Update `remote-bridge.zsh` to compute `REMOTE_BRIDGE_PORT` dynamically on remote SSH sessions instead of hardcoding 8377. Local sessions keep 8377 (the service port). The formula uses `cksum` on `$USER` to derive a deterministic port in the dynamic range.

### Acceptance criteria

- [ ] On remote SSH session: `echo $REMOTE_BRIDGE_PORT` outputs a port ≠ 8377, derived from `$USER`
- [ ] On local Mac: `echo $REMOTE_BRIDGE_PORT` still outputs 8377
- [ ] Two different usernames on the same server produce different ports
- [ ] Same username always produces the same port (deterministic)
- [ ] `remote-bridge-check` and `remote-bridge-status` use the computed port
- [ ] rclip/ropen/rnotify use the computed port (via existing `$REMOTE_BRIDGE_PORT` env var — no tool changes)

---

## Phase 2: sm tunnel with dynamic RemoteForward detection

**User stories**: As a user, `sm t3` detects the per-user port from SSH config and starts the tunnel correctly without hardcoding any port.

### What to build

Update `_sm_detect_bridge_port` to extract any RemoteForward port from `ssh -G` output instead of grepping for a specific port. Cache the `ssh -G` output to avoid double invocation. Remove `ExitOnForwardFailure` so autossh connects even if port is already bound by another session (same user — safe). Keep `ClearAllForwardings` on mosh bootstrap.

### Acceptance criteria

- [ ] `sm t3` detects RemoteForward 52916 (or whatever the per-user port is) from SSH config
- [ ] `sm plainserver` (no RemoteForward) still launches plain mosh
- [ ] If an existing SSH session already holds the port, autossh connects anyway (agent forwarding works)
- [ ] mosh bootstrap does not attempt RemoteForward (ClearAllForwardings)
- [ ] `ssh -G` is called once per `sm` invocation, not twice
- [ ] `sm-status` shows the per-user port

---

## Phase 3: SSH config helper + migration

**User stories**: As a user, I can run `remote-bridge-ssh-config t3` to get the correct RemoteForward line for my per-user port, and update my SSH config.

### What to build

Update `remote-bridge-ssh-config` to accept an optional hostname argument. When given, resolve the remote username via `ssh -G`, compute the per-user port, and output the correct `RemoteForward` line. Without argument, fall back to `$USER`. Update the user's Host t3 SSH config from `RemoteForward 8377 localhost:8377` to the computed per-user port.

### Acceptance criteria

- [ ] `remote-bridge-ssh-config t3` outputs `RemoteForward 52916 localhost:8377` (computed from remote user `kahl`)
- [ ] `remote-bridge-ssh-config` (no arg) computes from `$USER`
- [ ] Output includes the remote username and port derivation for transparency
- [ ] Host t3 in `~/.dotfiles-local/ssh-config` updated to use per-user port
- [ ] `ssh t3` forwards the per-user port (verified with `ss -tlnp` on remote)
- [ ] `sm t3` detects and uses the same port

---

## Phase 4: Documentation sync

**User stories**: As a future contributor (or future me), I can understand the per-user port architecture from the documentation.

### What to build

Update plan file, CLAUDE.md, and Remote Bridge docs to reflect per-user port architecture. Document the formula, the SSH config setup, and the shared-server isolation model.

### Acceptance criteria

- [ ] `plans/sm-mosh-tunnel.md` updated with per-user port decisions
- [ ] `CLAUDE.md` Remote Bridge section documents per-user port
- [ ] `sm` command documentation reflects dynamic detection
- [ ] `remote-bridge-ssh-config` helper documented

# Plan: Remote Bridge + SSH Agent over Unix Socket Forwards

> Source PRD: Design session 2026-07-21 — stale-tunnel incident on typo3 (half-dead
> autossh TCP connection held the bridge port and the only agent socket after
> network roaming; documented root-cause analysis and online research in session).

> Implementation status (2026-07-21): code, automated tests, private host tags,
> and documentation are complete. Acceptance criteria that require a live
> Mac-to-server tunnel or network roaming remain unchecked until rollout.

## Architectural decisions

Durable decisions that apply across all phases:

- **Transport**: The sm tunnel forwards two Unix domain sockets instead of a TCP
  port: `~/.ssh/remote-bridge.sock` (→ local `localhost:8377`) and
  `~/.ssh/agent-tunnel.sock` (→ local `$SSH_AUTH_SOCK`). Socket files are created
  by sshd with 0600 (default `StreamLocalBindMask 0177`, verified on typo3);
  `~/.ssh` is 0700. This replaces the per-user cksum port formula — per-user
  isolation now comes from `$HOME` for free.
- **Forwards never live in ssh_config**: Static-path RemoteForwards in the config
  would make every plain ssh session fight over the same socket paths (documented
  OpenSSH behavior: each new client destroys the previous forward) and would mask
  a dead tunnel during diagnostics. All `-R` forwards are passed explicitly by sm
  on the autossh command line only.
- **Host opt-in via `Tag remote-bridge`** in ssh_config (dotfiles-private).
  Readable through `ssh -G` (`tag remote-bridge` line), has zero forwarding side
  effects. Requires OpenSSH client ≥ 9.2 on the Mac. Replaces RemoteForward-line
  detection.
- **Cleanup principle — rm before bind, client-driven**: sshd never removes stale
  socket files, `StreamLocalBindUnlink yes` on typo3 is inert (present in
  `sshd_config.d/opener.conf` but the custom sshd_config has no Include —
  behaviorally verified 2026-07-21), and `.ssh/rc` runs after bind (OpenSSH bug
  2601). Therefore every connection attempt — including every autossh retry —
  first removes both socket paths over a `ClearAllForwardings=yes` exec
  connection. Implemented as an `AUTOSSH_PATH` ssh wrapper so retries self-heal
  in seconds. No root, no sshd changes required.
- **Heartbeat as TCP backstop**: The tunnel's remote command emits output every
  30s (client-side discarded) instead of `tail -f /dev/null`. On a half-dead
  connection the server's unacked writes hit the TCP retransmission timeout
  (`tcp_retries2=15` ≈ 15–20 min) and the stale sshd self-destructs even if no
  reconnect ever happens.
- **Verified reuse**: sm only reuses an existing tunnel after an end-to-end
  health check (`curl --unix-socket … /health` executed on the server via a
  `ClearAllForwardings=yes` ssh exec), not on process-aliveness alone.
- **One endpoint format per environment**: On Darwin (bridge host) clients use
  TCP `localhost:8377` as today; on remote hosts clients use the Unix socket.
  No dual-stack fallback, no port on remotes. A down tunnel means clients fail
  honestly (error, non-zero exit) — parity with the existing rclip/mosh policy.
- **Agent path is a constant**: `SSH_AUTH_SOCK=$HOME/.ssh/agent-tunnel.sock` on
  remote hosts (exported when the socket exists). No discovery, no symlink, no
  keeper daemon, no tmux refresh hooks, no `prefix + R`. The entire
  ssh-agent-keeper/find-socket machinery is deleted.
- **`ExitOnForwardFailure=yes` stays** — combined with pre-bind cleanup it can no
  longer dead-lock against a stale holder.
- **Preconditions**: curl ≥ 7.40 (`--unix-socket`) on every remote host;
  OpenSSH client ≥ 9.2 on the Mac (`Tag`); streamlocal forwarding allowed by the
  server sshd (verified on typo3; verify per host during rollout).

---

## Phase 1: Socket forwards in the sm tunnel (additive)

**User stories**: Tunnel survives roaming without manual repair; reconnects heal
themselves in seconds.

### What to build

sm forwards the two Unix sockets *in addition to* the existing RemoteForward
port, so nothing breaks while the new transport is proven. Before starting
autossh, sm runs one pre-flight exec over a forwarding-free connection that
removes both stale socket paths and captures the remote `$HOME` (needed for
absolute `-R` paths). A new `AUTOSSH_PATH` wrapper repeats that cleanup before
every ssh (re)start so each autossh retry self-heals. The remote command becomes
a 30s heartbeat loop with client-side output discarded. Tunnel reuse now
requires the end-to-end bridge health check to pass; a failed check tears the
tunnel down and starts fresh.

### Acceptance criteria

- [x] After `sm <host>`: both sockets exist on the server with mode 0600
- [x] On the server: `curl -sf --unix-socket ~/.ssh/remote-bridge.sock http://localhost/health` succeeds
- [x] On the server: `SSH_AUTH_SOCK=~/.ssh/agent-tunnel.sock ssh-add -l` lists the Mac's keys
- [ ] Kill the server-side tunnel sshd manually → autossh reconnects and both sockets work again without any manual cleanup (wrapper cleanup proven)
- [ ] Stale socket files present before `sm` start do not prevent the tunnel from establishing
- [x] `sm` on a broken-but-process-alive tunnel does not print "reusing" — it restarts and recovers
- [ ] Existing port-based rclip/rnotify still work unchanged (additive phase)

---

## Phase 2: Bridge clients on the Unix socket

**User stories**: rclip/ropen/rnotify/rtime/robsidian work identically on shared
servers without per-user ports; other local users cannot reach my bridge.

### What to build

Replace `remote-bridge/lib/bridge-port.sh` with an endpoint-resolution lib that
yields curl arguments: TCP `localhost:8377` on Darwin, `--unix-socket
$HOME/.ssh/remote-bridge.sock` elsewhere (env override for tests). Switch all
five clients to it; rclip's OSC52 fallback logic is untouched except for the
availability probe. Rewrite `remote-bridge.zsh` (health/status/test against the
socket; drop the tmux `REMOTE_BRIDGE_PORT` propagation — a constant path needs
none). Stop exporting `REMOTE_BRIDGE_PORT` from `.zshenv` on remotes. Extend
`remote-bridge/test` to cover endpoint resolution plus the failure modes:
socket file missing (clear error, non-zero exit) and unresponsive socket
(bounded timeout, no hang).

### Acceptance criteria

- [ ] On the server: `echo test | rclip`, `ropen <url>`, `rnotify test`, `rtime`, `robsidian` all work via the socket
- [x] With the socket file removed: each client fails fast with a specific, actionable error (no hang, no false success)
- [x] `rb-status` reports socket path + health correctly in both states
- [x] Tests cover: endpoint resolution (Darwin vs remote), missing socket, unresponsive socket
- [ ] tmux popups and new panes inherit working clients with no per-session env plumbing

---

## Phase 3: Constant agent path, delete the discovery machinery

**User stories**: `git push` works in any tmux pane after roaming/reconnect with
zero manual steps; no more "No working SSH agent found".

### What to build

Export `SSH_AUTH_SOCK=$HOME/.ssh/agent-tunnel.sock` on remote hosts when the
socket exists (`.zshenv`, so non-interactive shells get it too). Point the tmux
global environment at the same constant in `tmux.remote.conf` and delete the
refresh hooks, the `prefix + R` binding, and the symlink logic. Delete
`bin/ssh-agent-keeper`, `bin/ssh-agent-find-socket`, and
`zsh/config/ssh-agent.zsh` entirely; fold a one-line agent-socket probe into
`rb-status` so one command shows bridge + agent health. Update which-key menu,
cheatsheet, and tmux docs in the same commit.

### Acceptance criteria

- [ ] Fresh mosh session → `git push` works in a new tmux pane immediately
- [ ] Roam networks (or kill the tunnel sshd), wait for self-heal → `git push` works again with zero manual action
- [x] `rb-status` shows agent socket state (responsive / stale / absent)
- [x] `grep -r 'ssh_auth_sock\|ssh-agent-keeper\|find-socket'` over the repo returns only docs/history — no live code paths
- [x] Which-key, cheatsheet, and tmux docs no longer mention `prefix + R`

---

## Phase 4: Remove the port path, switch host config, docs sweep

**User stories**: One transport, one config surface; docs match reality.

### What to build

Switch sm detection from RemoteForward lines to `Tag remote-bridge` (verify
`ssh -V` ≥ 9.2 first). In dotfiles-private: remove the `RemoteForward <port>
localhost:8377` lines and tag the bridge hosts. Delete the cksum port formula,
`resolve_bridge_port`, and the `remote-bridge-ssh-config` helper (replaced by a
one-line "add `Tag remote-bridge`" hint in docs/status output). Sweep all doc
layers: root `CLAUDE.md`, `.claude/instructions/remote-bridge.md`,
`remote-bridge/README.md`, tmux docs; mark `plans/sm-per-user-port.md` as
superseded by this plan.

### Rollout checklist (same sitting, per host)

1. Merge dotfiles; `dot repos pull` on every server
2. Update dotfiles-private ssh config (remove RemoteForward, add Tag)
3. `sm-kill` all tunnels, start fresh `sm <host>` per host
4. Smoke per host: `rclip`/`rnotify`/`ropen`, `git push`, nvim `"+y`
5. One-time legacy cleanup per server: `rm -f ~/.ssh/rc ~/.ssh/ssh_auth_sock ~/.ssh/ssh-agent-keeper.{pid,log}` (the `~/.ssh/rc` symlink pointed at the deleted repo file that re-created the old agent symlink on every connection)
6. Verify curl ≥ 7.40 and streamlocal forwarding on each remaining host (pi, t3, …)

### Acceptance criteria

- [x] `grep -r 'REMOTE_BRIDGE_PORT\|bridge_user_port\|cksum'` in live code returns nothing (plans/history only)
- [x] `sm` on an untagged host runs plain mosh (no tunnel attempt); tagged host gets the full tunnel
- [x] No `RemoteForward` lines remain in ssh config for bridge purposes
- [x] All four doc layers describe the socket transport; troubleshooting section covers: stale socket file, tunnel down, tag missing
- [x] `plans/sm-per-user-port.md` marked superseded

#!/bin/sh
# Shared Remote Bridge endpoint resolution for all Remote Bridge callers
# (zsh/config/remote-bridge.zsh and the bash CLI clients: rclip, ropen,
# rnotify, rtime, and robsidian's remote/bridge-proxy branch).
# Source this file, then call resolve_bridge_endpoint().
#
# POSIX sh, function-definitions only — no `set -e`/`set -u`/`set -o
# pipefail` and no other top-level side effects. Shell options set here would
# leak into every client or interactive shell that sources it.

# Resolve the transport a client should use into three globals:
#   BRIDGE_BASE_URL    the scheme+host part of every request URL.
#   BRIDGE_SOCKET_PATH the resolved Unix socket path (non-Darwin only; unset
#                      on Darwin). Exposed for require_bridge_socket() and
#                      status reporting — not part of every caller's contract.
#   BRIDGE_ON_DARWIN   1 on Darwin, 0 otherwise. Plain global (not exported),
#                      cached so require_bridge_socket() and other lib
#                      functions branch on it instead of each re-running
#                      $(uname) themselves.
#
# On Darwin (the host running the bridge) requests go over TCP to the local
# service, same as before. Everywhere else — the sm tunnel forwards a Unix
# socket to the server instead of a TCP port — requests go over
# $HOME/.ssh/remote-bridge.sock. One socket path per $HOME gives per-user
# isolation without a shared TCP port.
resolve_bridge_endpoint() {
    if [ "$(uname)" = "Darwin" ]; then
        BRIDGE_ON_DARWIN=1
        BRIDGE_BASE_URL="http://localhost:8377"
        unset BRIDGE_SOCKET_PATH
    else
        BRIDGE_ON_DARWIN=0
        BRIDGE_SOCKET_PATH="${REMOTE_BRIDGE_SOCKET:-$HOME/.ssh/remote-bridge.sock}"
        BRIDGE_BASE_URL="http://localhost"
    fi
}

bridge_curl() {
    if [ "$BRIDGE_ON_DARWIN" = "1" ]; then
        curl "$@"
    else
        curl --unix-socket "$BRIDGE_SOCKET_PATH" "$@"
    fi
}

# Fail fast with an actionable error when the Unix socket file itself is
# missing — tunnel never started, or died and the wrapper hasn't self-healed
# yet. curl's own error for a missing --unix-socket path ("Couldn't connect
# to server") does not name the path or say what to do about it. No-op on
# Darwin, where there is no socket file to check. Must be called after
# resolve_bridge_endpoint().
require_bridge_socket() {
    if [ "$BRIDGE_ON_DARWIN" = "1" ]; then
        return 0
    fi
    if [ ! -S "$BRIDGE_SOCKET_PATH" ]; then
        echo "Error: Remote Bridge socket not found at $BRIDGE_SOCKET_PATH" >&2
        echo "Start the tunnel from the Mac: sm <host>" >&2
        return 1
    fi
}

# Probe the bridge's /health endpoint. Must be called after
# resolve_bridge_endpoint().
check_bridge_health() {
    bridge_curl -sf --connect-timeout 0.5 --max-time 2 "$BRIDGE_BASE_URL/health" >/dev/null 2>&1
}

report_bridge_unreachable() {
    if [ "$BRIDGE_ON_DARWIN" = "1" ]; then
        echo "Error: Remote Bridge is not responding at $BRIDGE_BASE_URL" >&2
    else
        echo "Error: Remote Bridge socket exists but is not responding: $BRIDGE_SOCKET_PATH" >&2
        echo "Restart the tunnel from the Mac: sm-kill <host>; sm <host>" >&2
    fi
}

# Fail fast with the standard actionable error when the bridge is
# unreachable. Used by clients that must hard-exit on an unreachable bridge
# (ropen, rnotify, rtime, robsidian). rclip is the one exception — it falls
# back to OSC52 instead of hard-failing, so it calls check_bridge_health()
# directly rather than this function. Must be called after
# resolve_bridge_endpoint().
require_bridge_reachable() {
    if ! check_bridge_health; then
        report_bridge_unreachable
        return 1
    fi
}

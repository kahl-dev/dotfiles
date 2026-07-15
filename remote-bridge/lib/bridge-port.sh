#!/bin/sh
# Shared per-user Remote Bridge port formula for all Remote Bridge callers
# (interactive/non-interactive zsh via .zshenv, zsh/config/remote-bridge.zsh,
# and the bash CLI clients: rclip, ropen, rnotify, rtime, robsidian).
# Source this file, then call bridge_user_port() or resolve_bridge_port().
#
# POSIX sh, function-definitions only — no `set -e`/`set -u`/`set -o
# pipefail` and no other top-level side effects. This is sourced into
# interactive login shells via .zshenv; errexit/nounset at file scope here
# would leak into every shell that sources it.

# Deterministic per-user Remote Bridge port (POSIX cksum), range 49152-65534.
# Same username always produces the same port — avoids well-known/dynamic
# port collisions and prevents cross-talk on shared servers.
bridge_user_port() {
    echo $(( 49152 + $(printf '%s' "$1" | cksum | cut -d' ' -f1) % 16383 ))
}

# Resolve the port a client should use: explicit env first; otherwise derive.
# On macOS (the host running the bridge) it's the fixed 8377; on a remote
# host it's the per-user port (prevents cross-talk on shared servers).
resolve_bridge_port() {
    if [ -n "${REMOTE_BRIDGE_PORT:-}" ]; then
        printf '%s' "$REMOTE_BRIDGE_PORT"
    elif [ "$(uname)" != "Darwin" ]; then
        bridge_user_port "$USER"
    else
        printf '%s' "8377"
    fi
}

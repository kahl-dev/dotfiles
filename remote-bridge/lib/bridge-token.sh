#!/usr/bin/env bash

# Shared token resolution for all Remote Bridge CLI clients (rclip, ropen,
# rnotify, rtime, and robsidian's remote/bridge-proxy branch).
# Source this file, then call resolve_bridge_token().

# Resolve the Bearer token: env var first, then atuin's synced dotfiles vars.
# launchd's minimal PATH means `atuin` may not be resolvable by name, so probe
# known install locations before falling back to `which`.
#
# Callers run under `set -euo pipefail`. The atuin lookup below legitimately
# exits non-zero when atuin isn't installed or has no matching var, and each
# `|| true` / early `return 1` keeps that from tripping errexit inside this
# function. The caller must still guard its OWN assignment the same way —
# `TOKEN="$(resolve_bridge_token || true)"` — otherwise a return 1 here
# (env unset, atuin unauthenticated) propagates through the bare command
# substitution and kills the script silently, before the caller's own
# "TOKEN not set" error message ever runs.
resolve_bridge_token() {
    if [ -n "${REMOTE_BRIDGE_TOKEN:-}" ]; then
        printf '%s' "$REMOTE_BRIDGE_TOKEN"
        return 0
    fi

    local atuin_bin=""
    for candidate in "${HOME}/.atuin/bin/atuin" "/opt/homebrew/bin/atuin" "/usr/local/bin/atuin"; do
        if [ -x "$candidate" ]; then
            atuin_bin="$candidate"
            break
        fi
    done
    [ -z "$atuin_bin" ] && atuin_bin=$(command -v atuin 2>/dev/null || true)
    [ -z "$atuin_bin" ] && return 1

    local line
    line=$("$atuin_bin" dotfiles var list 2>/dev/null | grep '^export REMOTE_BRIDGE_TOKEN=' | head -1 || true)
    [ -z "$line" ] && return 1

    # Extract the value after `=` (handles `=` appearing inside the value
    # itself, unlike `cut -d= -f2-` which also works here but this keeps the
    # intent explicit: strip exactly the known prefix).
    local value="${line#export REMOTE_BRIDGE_TOKEN=}"

    # Trim leading/trailing whitespace to match the server's .trim()
    # (src/server.js resolveExpectedToken). A padded stored value would
    # otherwise never equal the server's expected token, so every request
    # would 401 — a self-inflicted denial of service.
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

# Resolve the token and print the caller's standard "not set" error.
# Returns (not exits) on failure: this runs inside the caller's
# `TOKEN="$(require_bridge_token)"` command substitution subshell, where
# `exit` would only terminate that subshell — the client would then continue
# with an empty TOKEN. The caller supplies the actual exit via `|| exit 1`.
require_bridge_token() {
    local token
    token="$(resolve_bridge_token || true)"
    if [ -z "$token" ]; then
        echo "Error: REMOTE_BRIDGE_TOKEN not set (env or atuin)" >&2
        return 1
    fi
    printf '%s' "$token"
}

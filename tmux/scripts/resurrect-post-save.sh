#!/usr/bin/env bash
# Post-save hook for tmux-resurrect.
#
# 1. Skip-empty-save guard: if the just-written snapshot has no `pane` lines
#    (e.g. continuum saved a session-less server right after a reboot, or the
#    save was interrupted), drop it and re-point `last` at the most recent
#    non-empty snapshot. Prevents continuum's auto-restore from loading an
#    empty state and silently dropping pre-reboot work.
# 2. Cleanup: keep only the most recent 50 snapshots to bound disk growth.
#
# Runs silently — fires on every save (continuum every 15min + on
# session-closed). Real recovery notifications live in the companion
# pre-restore hook.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/resurrect-lib.sh"

if [[ -L "$LAST" ]]; then
    current_target="$(readlink "$LAST")"
    current_path="${RESURRECT_DIR}/${current_target}"

    if [[ -f "$current_path" ]] && ! has_pane_lines "$current_path"; then
        fallback="$(find_valid_fallback "$current_target")"
        rm -f "$current_path"
        if [[ -n "$fallback" ]]; then
            ln -sfn "$fallback" "$LAST"
        else
            rm -f "$LAST"
        fi
    fi
fi

ls -t "$RESURRECT_DIR"/tmux_resurrect_*.txt 2>/dev/null \
    | tail -n +51 \
    | xargs -r rm -f 2>/dev/null || true

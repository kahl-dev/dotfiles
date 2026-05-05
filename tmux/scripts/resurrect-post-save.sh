#!/usr/bin/env bash
# Post-save hook for tmux-resurrect.
#
# 1. Skip-empty-save guard: if the just-written snapshot has no `pane` lines
#    (e.g. continuum saved a session-less server right after a reboot, or the
#    save was interrupted), drop it and re-point `last` at the most recent
#    non-empty snapshot. Prevents continuum's auto-restore from loading an
#    empty state and silently dropping pre-reboot work.
# 2. Cleanup: keep only the most recent 50 snapshots to bound disk growth.

set -euo pipefail

RESURRECT_DIR="${HOME}/.dotfiles/tmux/resurrect"
LAST="${RESURRECT_DIR}/last"

has_pane_lines() {
    grep -qE '^pane[[:space:]]' "$1" 2>/dev/null
}

if [[ -L "$LAST" ]]; then
    current_target="$(readlink "$LAST")"
    current_path="${RESURRECT_DIR}/${current_target}"

    if [[ -f "$current_path" ]] && ! has_pane_lines "$current_path"; then
        previous=""
        while IFS= read -r snapshot; do
            [[ "$snapshot" == "$current_target" ]] && continue
            if has_pane_lines "${RESURRECT_DIR}/${snapshot}"; then
                previous="$snapshot"
                break
            fi
        done < <(cd "$RESURRECT_DIR" && ls -1t tmux_resurrect_*.txt 2>/dev/null)

        rm -f "$current_path"
        if [[ -n "$previous" ]]; then
            ln -sfn "$previous" "$LAST"
        else
            rm -f "$LAST"
        fi
    fi
fi

ls -t "$RESURRECT_DIR"/tmux_resurrect_*.txt 2>/dev/null \
    | tail -n +51 \
    | xargs -r rm -f 2>/dev/null || true

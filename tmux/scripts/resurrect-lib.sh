#!/usr/bin/env bash
# Shared helpers for tmux-resurrect hook scripts.
# Sourced by resurrect-post-save.sh and resurrect-pre-restore.sh.
#
# Defines:
#   RESURRECT_DIR, LAST  — canonical paths
#   has_pane_lines FILE  — true iff FILE contains at least one `^pane` line
#   find_valid_fallback CURRENT  — newest non-CURRENT snapshot with pane
#                                  lines, printed to stdout; empty if none

RESURRECT_DIR="${HOME}/.dotfiles/tmux/resurrect"
LAST="${RESURRECT_DIR}/last"

has_pane_lines() {
    grep -qE '^pane[[:space:]]' "$1" 2>/dev/null
}

find_valid_fallback() {
    local skip="$1" snapshot
    while IFS= read -r snapshot; do
        [[ "$snapshot" == "$skip" ]] && continue
        if has_pane_lines "${RESURRECT_DIR}/${snapshot}"; then
            printf '%s\n' "$snapshot"
            return 0
        fi
    done < <(cd "$RESURRECT_DIR" && ls -1t tmux_resurrect_*.txt 2>/dev/null)
}

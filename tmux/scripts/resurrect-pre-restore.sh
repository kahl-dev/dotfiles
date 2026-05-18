#!/usr/bin/env bash
# Pre-restore hook for tmux-resurrect.
#
# Runs immediately before tmux-resurrect's restore reads `last`. If the
# symlink points to a snapshot with no `pane` lines (typical aftermath of
# a save that was killed mid-write by a reboot), repair it.
#
# Notifies via display-message (unlike the routinely-firing post-save
# guard) because this path only triggers on real recovery from data loss.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/resurrect-lib.sh"

format_timestamp() {
    local filename="$1"
    if [[ "$filename" =~ tmux_resurrect_([0-9]{4})([0-9]{2})([0-9]{2})T([0-9]{2})([0-9]{2})[0-9]{2}\.txt ]]; then
        printf '%s-%s-%s %s:%s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}"
    else
        printf '%s' "$filename"
    fi
}

notify() {
    tmux display-message "$1" 2>/dev/null || true
}

[[ -L "$LAST" ]] || exit 0

current_target="$(readlink "$LAST")"
current_path="${RESURRECT_DIR}/${current_target}"

has_pane_lines "$current_path" && exit 0

fallback="$(find_valid_fallback "$current_target")"
rm -f "$current_path"

if [[ -n "$fallback" ]]; then
    ln -sfn "$fallback" "$LAST"
    notify "resurrect: skipped empty snapshot, restored from $(format_timestamp "$fallback")"
else
    rm -f "$LAST"
    notify "resurrect: no valid snapshot found, starting fresh"
fi

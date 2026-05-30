#!/usr/bin/env bash
# Pre-restore hook for tmux-resurrect — revive background Claude sessions once
# per boot.
#
# After a reboot the Claude supervisor and its background workers are dead, but
# their state persists in ~/.claude/daemon/roster.json. `claude respawn --all`
# restarts every roster session from that saved state (verified: revives a
# session whose worker process was killed). Foreground/interactive sessions are
# NOT in the roster — they come back through their tmux panes via the companion
# patcher (claude-resurrect-patch.sh) — so respawn touches only true background
# sessions. No double-revive.
#
# Gated on a per-boot marker so it fires exactly once after an ACTUAL reboot,
# never on a manual `tmux kill-server` restart (which would needlessly restart —
# and interrupt — live background sessions). Best-effort: always exits 0 so the
# resurrect hook chain stays intact.

set -uo pipefail

command -v claude >/dev/null 2>&1 || exit 0
[ -s "$HOME/.claude/daemon/roster.json" ] || exit 0   # no bg sessions ever recorded

# Boot identity: changes on every reboot, stable within a boot. macOS exposes
# kern.boottime; Linux has boot_id (or uptime -s as a last resort).
current_boot_id() {
    local id
    if id="$(sysctl -n kern.boottime 2>/dev/null)" && [ -n "$id" ]; then
        printf '%s' "$id"
    elif [ -r /proc/sys/kernel/random/boot_id ]; then
        cat /proc/sys/kernel/random/boot_id
    else
        uptime -s 2>/dev/null
    fi
}

# Guard on the RAW id: cksum of empty input is the constant 4294967295, which
# would silently pin the marker forever (respawn never re-fires). If no boot
# source resolves, skip rather than write a bogus constant.
boot_raw="$(current_boot_id)"
[ -n "$boot_raw" ] || exit 0
boot="$(printf '%s' "$boot_raw" | cksum | awk '{print $1}')"
[ -n "$boot" ] || exit 0

marker="$HOME/.claude/.last-respawn-boot"
if [ -f "$marker" ] && [ "$(cat "$marker" 2>/dev/null)" = "$boot" ]; then
    exit 0   # already revived this boot
fi
printf '%s' "$boot" >"$marker" 2>/dev/null || exit 0

# Async + detached so the restore is never blocked on respawn (~1-2s/session).
(claude respawn --all >/dev/null 2>&1 &)
exit 0

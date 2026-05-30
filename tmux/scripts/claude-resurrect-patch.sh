#!/usr/bin/env bash
# Post-save hook for tmux-resurrect.
#
# Patches the just-saved snapshot so each claude-running pane is restored
# with `claude --resume <session-id>` instead of bare `claude`. Source of
# truth: ~/.claude/sessions/<pid>.json (written by Claude itself).
#
# Algorithm:
#   1. For each ~/.claude/sessions/*.json: validate PID alive, extract
#      sessionId, verify a transcript jsonl exists for it (filters out
#      non-conversation processes like `claude agents`), get its TTY.
#   2. One awk pass joins TTY->pane-coords (from `tmux list-panes`) with
#      TTY->sessionId (from step 1) and rewrites each matching pane's
#      full-command to `:claude --resume <sessionId>`.
#   3. Atomic replace.
#
# Best-effort: exits 0 on any internal failure so the resurrect hook chain
# stays intact. Compatible with macOS bash 3.2 (no associative arrays).

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/resurrect-lib.sh" || exit 0

command -v jq >/dev/null 2>&1 || exit 0
command -v tmux >/dev/null 2>&1 || exit 0
[[ -d "$HOME/.claude/sessions" ]] || exit 0
[[ -L "$LAST" ]] || exit 0

target="$(readlink "$LAST")"
snapshot="${RESURRECT_DIR}/${target}"
[[ -f "$snapshot" ]] || exit 0

panes="$(tmux list-panes -a -F '#{pane_tty}	#{session_name}	#{window_index}	#{pane_index}' 2>/dev/null)" || exit 0
[[ -n "$panes" ]] || exit 0

# Collect TTY->sessionId for every live interactive Claude (one line per session).
tty_sid=""
for f in "$HOME"/.claude/sessions/*.json; do
    [[ -f "$f" ]] || continue
    pid="${f##*/}"; pid="${pid%.json}"
    [[ "$pid" =~ ^[0-9]+$ ]] || continue
    kill -0 "$pid" 2>/dev/null || continue

    sid="$(jq -r '.sessionId // empty' "$f" 2>/dev/null)"
    [[ -n "$sid" ]] || continue

    # Transcript must exist — filters claude agents / non-conversation procs.
    # Glob into an array (fork-free). `:-` keeps it safe under both the default
    # (unmatched glob stays literal) and `nullglob` (empty array) with set -u.
    transcripts=( "$HOME"/.claude/projects/*/"${sid}.jsonl" )
    [[ -e "${transcripts[0]:-}" ]] || continue

    # `ps -p PID -o tty=` returns the short form (ttys003 / pts/4) on both
    # macOS and Linux; tmux #{pane_tty} returns /dev/<short>.
    tty="$(ps -p "$pid" -o tty= 2>/dev/null | tr -d ' ')"
    [[ -n "$tty" && "$tty" != "?" && "$tty" != "??" ]] || continue

    tty_sid+="${tty}"$'\t'"${sid}"$'\n'
done
[[ -n "$tty_sid" ]] || exit 0

# Temp file lives in RESURRECT_DIR (same filesystem as $snapshot) so the final
# `mv` is a real atomic rename, not a cross-filesystem copy+unlink. The name
# does not match resurrect's `tmux_resurrect_*.txt` cleanup glob.
snapshot_tmp="$(mktemp "${RESURRECT_DIR}/claude-resurrect-snap.XXXXXX")"
trap 'rm -f "$snapshot_tmp"' EXIT

# Single pass: join panes (TTY->coords) with tty_sid (TTY->sessionId) into
# coords->sessionId, then rewrite matching pane lines. Inputs arrive via the
# environment so awk does not escape-process them.
#
# Resurrect pane line fields ($1..$NF, tab-separated): $1="pane" $2=session
# $3=window-index $6=pane-index $NF=":<full-command>". Coords = $2:$3.$6.
# Rewrite $NF only for an actual claude command (anchored — a substring match
# would clobber e.g. `vim ~/.claude/x` if it ever shared a resolved pane).
CR_PANES="$panes" CR_TTYSID="$tty_sid" awk -F'\t' -v OFS='\t' '
BEGIN {
    n = split(ENVIRON["CR_PANES"], pl, "\n")
    for (i = 1; i <= n; i++) {
        if (pl[i] == "") continue
        split(pl[i], p, "\t")
        t = p[1]; sub(/^\/dev\//, "", t)
        tty2coords[t] = p[2] ":" p[3] "." p[4]
    }
    m = split(ENVIRON["CR_TTYSID"], sl, "\n")
    for (i = 1; i <= m; i++) {
        if (sl[i] == "") continue
        split(sl[i], s, "\t")
        if (s[1] in tty2coords) coords2sid[tty2coords[s[1]]] = s[2]
    }
}
$1 == "pane" {
    coords = $2 ":" $3 "." $6
    if (coords in coords2sid && $NF ~ /^:claude([[:space:]]|$)/) {
        $NF = ":claude --resume " coords2sid[coords]
    }
}
{ print }
' "$snapshot" >"$snapshot_tmp"

# Sanity check before replacing — don't corrupt resurrect state.
if [[ -s "$snapshot_tmp" ]] && has_pane_lines "$snapshot_tmp"; then
    mv "$snapshot_tmp" "$snapshot"
fi

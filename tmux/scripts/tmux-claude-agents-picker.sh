#!/usr/bin/env bash
# tmux-claude-agents-picker.sh — Pick a live Claude Code agent, then launch
# lazygit / yazi / btop / glow in that agent's cwd. Wired into the apps
# key-table as `Prefix + a → c`.
#
# Background: Claude Code's "Agent View" (`claude agents`) runs each
# background agent as its own OS process with its own cwd, but the tmux
# pane is owned by the agent-view supervisor whose cwd is fixed. Therefore
# `#{pane_current_path}` cannot follow the foregrounded agent. This picker
# lists live agents from `claude agents --json` and lets the user pick the
# target cwd explicitly.
set -euo pipefail

# ---------------------------------------------------------------------------
# Preview mode — re-invoked by fzf with (cache_file, sessionId). Looks the
# row up in the cache and prints a formatted block. Run inside fzf for each
# highlighted row, so it must be fast and self-contained.
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "__preview" ]]; then
    cache="${2:-}"
    sid="${3:-}"

    if [[ "$sid" == "-" ]]; then
        printf '(no live agents)\n\n'
        printf 'Press Enter to open the app menu,\n'
        printf "which will launch in this pane's cwd.\n\n"
        printf 'Esc to cancel.\n'
        exit 0
    fi

    row="$(awk -F'\t' -v s="$sid" '$3 == s { print; exit }' "$cache" 2>/dev/null || true)"
    [[ -z "$row" ]] && exit 0

    IFS=$'\t' read -r _display cwd sessionId state detail name kind status started_ms <<<"$row"

    if [[ "$started_ms" =~ ^[0-9]+$ ]] && (( started_ms > 0 )); then
        now_s=$(date +%s)
        diff=$(( now_s - started_ms / 1000 ))
        if   (( diff < 60 ));    then age="${diff}s ago"
        elif (( diff < 3600 ));  then age="$(( diff / 60 ))m ago"
        elif (( diff < 86400 )); then age="$(( diff / 3600 ))h ago"
        else                          age="$(( diff / 86400 ))d ago"
        fi
    else
        age="?"
    fi

    # Length-based strip avoids glob-pattern semantics of ${var/#pattern/}
    # which would mis-handle HOME paths containing `[`/`*`/`?` metacharacters.
    if [[ "$cwd" == "$HOME"* ]]; then
        cwd_short="~${cwd:${#HOME}}"
    else
        cwd_short="$cwd"
    fi
    project="$(basename "$cwd")"
    sid_short="${sessionId:0:8}"

    printf '%s\n' "$name"
    printf '━%.0s' {1..40}; printf '\n\n'
    printf 'kind     %s\n' "$kind"
    printf 'state    %s\n' "${state:-$status}"
    [[ -n "$detail" ]] && printf '\n%s\n' "$detail"
    printf '\nProject  %s\n' "$project"
    printf 'cwd      %s\n' "$cwd_short"
    printf 'Started  %s\n' "$age"
    printf 'Session  %s\n' "$sid_short"
    exit 0
fi

# ---------------------------------------------------------------------------
# Normal mode
# ---------------------------------------------------------------------------
# SCRIPT_PATH is only needed for the fzf --preview re-invocation below;
# computing it after the __preview early-exit saves a subshell fork per
# preview row.
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

FALLBACK_CWD="${1:-$HOME}"

for dep in claude fzf jq; do
    if ! command -v "$dep" &>/dev/null; then
        tmux display-message "tmux-claude-agents: $dep not installed" 2>/dev/null \
            || echo "tmux-claude-agents: $dep not installed" >&2
        exit 1
    fi
done

# Catppuccin colors from shared fzf-lib.sh.
# shellcheck source=fzf-lib.sh disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/fzf-lib.sh" || {
    tmux display-message "tmux-claude-agents: cannot source fzf-lib.sh" 2>/dev/null \
        || echo "tmux-claude-agents: cannot source fzf-lib.sh" >&2
    exit 1
}

CACHE_FILE="$(mktemp "${TMPDIR:-/tmp}/cc-agents-XXXXXX")"
trap 'rm -f "$CACHE_FILE"' EXIT

# Build a lookup map from sessionId → rich state.json blob. The keys cover
# both `state.json.resumeSessionId` (matches `claude agents --json` sessionId
# for background agents) and `state.json.sessionId` (the daemon's own id).
STATE_MAP="$(
    if compgen -G "$HOME/.claude/jobs/*/state.json" >/dev/null 2>&1; then
        jq -s '
            reduce .[] as $s ({};
                  (if $s.resumeSessionId != null
                      then . + { ($s.resumeSessionId): $s } else . end)
                | (if $s.sessionId != null
                      then . + { ($s.sessionId): $s } else . end)
            )
        ' "$HOME"/.claude/jobs/*/state.json 2>/dev/null || echo '{}'
    else
        echo '{}'
    fi
)"

AGENTS_JSON="$(claude agents --json 2>/dev/null || echo '[]')"

# TSV row layout (per agent) — KEEP IN SYNC with the IFS read in the preview
# block above AND with the dispatch read at the bottom of this file:
#   1 display     fzf-rendered string (already includes name/kind/status/cwd)
#   2 cwd         absolute path, used for `display-popup -d`
#   3 sessionId   UUID, used by fzf preview `{3}` to look up enrichment
#   4 state       from state.json (empty for interactive sessions)
#   5 detail      from state.json `.detail` (or `.needs` fallback)
#   6 name        from `claude agents --json` (or state.json fallback)
#   7 kind        `bg` / `int` (abbreviated via object lookup)
#   8 status      `busy` / `idle` from `claude agents --json`
#   9 startedAt   epoch MILLISECONDS (note: ms, not s — preview divides by 1000)
#
# Sort: busy first, then idle, recency desc as tiebreak.
printf '%s' "$AGENTS_JSON" | jq -r --argjson states "$STATE_MAP" --arg home "$HOME" '
    def rpad($n): tostring | (. + (" " * 80))[:$n];
    def strip_specials: tostring | gsub("[\\n\\t\\r]"; " ");

    sort_by([
        (if .status == "busy" then 0 else 1 end),
        -(.startedAt // 0)
    ])
    | .[]
    | . as $a
    | ($states[$a.sessionId] // {}) as $s
    | (($a.name // $s.name // "(unnamed)") | strip_specials) as $name
    | (($a.kind // "?") | ({"background":"bg","interactive":"int"}[.] // .) | strip_specials) as $kind
    | (($a.status // "?") | strip_specials) as $status
    | (($a.cwd // "") | tostring | if startswith($home) then "~" + ltrimstr($home) else . end) as $cwd_short
    | (($s.state // "") | strip_specials) as $state
    # `.detail` is the active state.json description; `.needs` is the older
    # field still set on idle agents waiting for input — fall back when the
    # newer field is absent so we always have something to show in the preview.
    | (($s.detail // $s.needs // "") | strip_specials) as $detail
    | [
        (($name | rpad(22)) + " " + ($kind | rpad(3)) + " " + ($status | rpad(5)) + " " + $cwd_short),
        ($a.cwd // ""),
        ($a.sessionId // ""),
        $state,
        $detail,
        $name,
        $kind,
        $status,
        (($a.startedAt // 0) | tostring)
      ]
    | @tsv
' >"$CACHE_FILE"

# Graceful fallback when no live agents exist
if [[ ! -s "$CACHE_FILE" ]]; then
    printf '(no live agents — Esc to cancel)\t%s\t-\t-\t-\t(no live agents)\t-\t-\t0\n' \
        "$FALLBACK_CWD" >"$CACHE_FILE"
fi

header=' Type to filter · Enter to pick agent · Esc cancel '

# Stage 1 — filter and pick the agent. fzf is a pure picker here: typed
# letters filter freely (no --expect that would steal g/y/b/m from search).
row="$(
    fzf-tmux -p 80%,70% \
        --ansi \
        --no-sort \
        --delimiter=$'\t' \
        --with-nth=1 \
        --border-label ' 󰚩 Claude Agents ' \
        --border-label-pos=2 \
        --prompt '⚡ ' \
        --pointer='▶' \
        --header "$header" \
        --color "$FZF_CATPPUCCIN_COLORS" \
        --preview "bash '$SCRIPT_PATH' __preview '$CACHE_FILE' '{3}'" \
        --preview-window 'right:50%:wrap' \
        --bind 'tab:down,btab:up' \
        <"$CACHE_FILE" \
    || true
)"

[[ -z "$row" ]] && exit 0

# Mirrors the IFS read pattern in the preview block above.
IFS=$'\t' read -r _display cwd _sid _state _detail name _kind _status _started <<<"$row"

if [[ -z "$cwd" || ! -d "$cwd" ]]; then
    tmux display-message "tmux-claude-agents: directory not found: $cwd" 2>/dev/null
    exit 1
fi

# Stage 2 — app selector. Stash the agent context as tmux user options so
# display-menu can reference them via format expansion (#{...}). Safer than
# shell-interpolating $cwd, which may contain single quotes.
tmux set-option -g @cc_picker_cwd  "$cwd"
tmux set-option -g @cc_picker_name "$name"

tmux display-menu -xC -yC -T " 󰚩 #{@cc_picker_name} " \
    "" \
    "  [g] Lazygit"  "g"  "display-popup -E -w 90% -h 90% -d \"#{@cc_picker_cwd}\" 'lazygit'" \
    "  [y] Yazi"     "y"  "display-popup -E -w 90% -h 90% -d \"#{@cc_picker_cwd}\" 'yazi'" \
    "  [b] btop"     "b"  "display-popup -E -w 90% -h 90% -d \"#{@cc_picker_cwd}\" 'btop'" \
    "  [m] glow"     "m"  "display-popup -E -w 90% -h 90% -d \"#{@cc_picker_cwd}\" 'glow'" \
    "" \
    "  [Esc] Cancel" "Escape" ""

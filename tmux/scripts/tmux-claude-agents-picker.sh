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

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

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
        printf 'Press g/y/b/m to launch the app\n'
        printf "in this pane's cwd.\n\n"
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

    cwd_short="${cwd/#$HOME/\~}"
    project="$(basename "$cwd")"
    sid_short="${sessionId:0:8}"
    effective_state="${state:-$status}"

    printf '%s\n' "$name"
    printf '━%.0s' {1..40}; printf '\n\n'
    printf 'kind     %s\n' "$kind"
    printf 'state    %s\n' "$effective_state"
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
FALLBACK_CWD="${1:-$HOME}"

for dep in claude fzf jq; do
    if ! command -v "$dep" &>/dev/null; then
        tmux display-message "tmux-claude-agents: $dep not installed" 2>/dev/null \
            || echo "tmux-claude-agents: $dep not installed" >&2
        exit 1
    fi
done

# Catppuccin Mocha — duplicated from FZF_DEFAULT_OPTS because run-shell
# does not inherit zsh-exported environment. Mirrors tmux-sesh.sh.
FZF_COLORS="bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
FZF_COLORS+=",fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
FZF_COLORS+=",marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

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

# TSV row layout (per agent):
#   1 display  2 cwd  3 sessionId  4 state  5 detail  6 name  7 kind
#   8 status   9 startedAt
# Display (col 1) is what fzf shows; the rest are queried by preview &
# dispatch. Sort: busy first, then idle, recency desc as tiebreak.
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
    | (($a.kind // "?") |
        if   . == "background"  then "bg"
        elif . == "interactive" then "int"
        else .
        end | strip_specials) as $kind
    | (($a.status // "?") | strip_specials) as $status
    | (($a.cwd // "") | tostring | sub("^" + $home; "~")) as $cwd_short
    | (($s.state // "") | strip_specials) as $state
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

header=' g/Enter lazygit · y yazi · b btop · m glow · Esc cancel '

selection="$(
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
        --color "$FZF_COLORS" \
        --preview "bash '$SCRIPT_PATH' __preview '$CACHE_FILE' {3}" \
        --preview-window 'right:50%:wrap' \
        --expect='g,y,b,m' \
        --bind 'tab:down,btab:up' \
        <"$CACHE_FILE" \
    || true
)"

[[ -z "$selection" ]] && exit 0

key="$(printf '%s\n' "$selection" | sed -n '1p')"
row="$(printf '%s\n' "$selection" | sed -n '2p')"

[[ -z "$row" ]] && exit 0

cwd="$(printf '%s' "$row" | awk -F'\t' '{print $2}')"

if [[ -z "$cwd" || ! -d "$cwd" ]]; then
    tmux display-message "tmux-claude-agents: directory not found: $cwd" 2>/dev/null
    exit 1
fi

case "$key" in
    y) app="yazi" ;;
    b) app="btop" ;;
    m) app="glow" ;;
    g|"") app="lazygit" ;;
    *)    app="lazygit" ;;
esac

tmux display-popup -E -w 90% -h 90% -d "$cwd" "$app"

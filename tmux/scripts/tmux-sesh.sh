#!/usr/bin/env bash
# tmux-sesh.sh — Session manager powered by sesh + fzf
# Works both inside tmux (popup via Prefix+o) and outside (shell via `tm`)
set -euo pipefail

if ! command -v sesh &>/dev/null; then
    echo "sesh is not installed. Install with: brew install sesh" >&2
    exit 1
fi

if ! command -v fzf &>/dev/null; then
    echo "fzf is not installed. Install with: brew install fzf" >&2
    exit 1
fi

# Catppuccin Mocha colors — duplicated from FZF_DEFAULT_OPTS because
# run-shell invocations don't inherit zsh-exported environment
FZF_COLORS="bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
FZF_COLORS+=",fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
FZF_COLORS+=",marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

if [[ -n "${TMUX:-}" ]]; then
    current_session=$(tmux display-message -p '#S')
    border_label=" 󰆍 sesh (current: ${current_session}) "
else
    border_label=" 󰆍 sesh "
fi

header=$' ^a all  ^t tmux  ^x zoxide  ^n new  ^d kill  ^f find'

# ctrl-d: only kills if target is an active tmux session, saves resurrect state first
kill_command='session={2..}; tmux has-session -t "$session" 2>/dev/null && tmux confirm-before -p "kill session $session? (y/n)" "kill-session -t \"$session\" \; run-shell \"~/.dotfiles/tmux/plugins/tmux-resurrect/scripts/save.sh >/dev/null 2>&1 || true\"" || tmux display-message "Not a tmux session"'

fzf_args=(
    --ansi
    --no-sort
    --border-label "$border_label"
    --prompt '⚡ '
    --header "$header"
    --bind 'tab:down,btab:up'
    --bind 'ctrl-a:change-prompt(⚡ )+reload(sesh list --icons)'
    --bind 'ctrl-t:change-prompt(🪟 )+reload(sesh list -t --icons)'
    --bind 'ctrl-x:change-prompt(📁 )+reload(sesh list -z --icons)'
    --bind "ctrl-n:become(echo NEW_SESSION:{})"
    --bind "ctrl-d:execute($kill_command)+reload(sleep 0.2 && sesh list --icons)"
    --bind 'ctrl-f:change-prompt(🔎 )+reload(fd --type d --hidden --exclude .git --exclude node_modules --exclude .cache --max-depth 4 . ~)'
    --preview-window 'right:55%'
    --preview 'sesh preview {}'
    --color "$FZF_COLORS"
)

run_fzf() {
    if [[ -n "${TMUX:-}" ]]; then
        fzf-tmux -p 80%,70% "${fzf_args[@]}"
    else
        fzf "${fzf_args[@]}"
    fi
}

session_list=$(sesh list --icons)
selected=$(printf '%s\n' "$session_list" | run_fzf) || exit 0
[[ -z "$selected" ]] && exit 0

if [[ "$selected" == NEW_SESSION:* ]]; then
    raw="${selected#NEW_SESSION:}"
    # Strip leading icon field (sesh list --icons prepends an icon + space)
    target="${raw#* }"

    if [[ "$target" == ~* || "$target" == /* ]]; then
        session_path="${target/#\~/$HOME}"
        base=$(basename "$session_path")
    else
        session_path=$(tmux display-message -t "$target" -p "#{session_path}" 2>/dev/null)
        base="$target"
    fi
    if [[ -z "$session_path" ]]; then
        echo "Session '$target' no longer exists or has no path" >&2
        exit 1
    fi

    name="$base"
    counter=2
    max_attempts=20
    while ! tmux new-session -d -s "$name" -c "$session_path" 2>/dev/null; do
        if (( counter > max_attempts )); then
            echo "Failed to create session '${base}' after ${max_attempts} attempts" >&2
            exit 1
        fi
        name="${base}-${counter}"
        ((counter++))
    done

    if [[ -n "${TMUX:-}" ]]; then
        tmux switch-client -t "$name"
    else
        tmux attach-session -t "$name"
    fi
else
    sesh connect "$selected"
fi

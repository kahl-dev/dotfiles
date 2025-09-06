#!/usr/bin/env bash

# TMUX Cheatsheet Interactive Search
# Quick lookup of specific tmux keybindings using fzf

CHEATSHEET_FILE="$HOME/.dotfiles/tmux/cheatsheet.md"

# Check if files exist
if [[ ! -f "$CHEATSHEET_FILE" ]]; then
    echo "Error: Cheatsheet file not found at $CHEATSHEET_FILE"
    exit 1
fi

if ! command -v fzf >/dev/null 2>&1; then
    echo "Error: fzf not found. Please install fzf for search functionality."
    exit 1
fi

# Extract keybinding lines from the cheatsheet
# Look for lines with keybinding patterns and descriptions
grep -E "│.*(<prefix>|C-|M-)" "$CHEATSHEET_FILE" | \
    sed 's/^│ *//; s/ *│$//' | \
    fzf \
        --height=40% \
        --layout=reverse \
        --border \
        --prompt="🔍 Search keybindings: " \
        --preview-window=hidden \
        --header="Press ENTER to copy command, ESC to exit" \
        --bind="enter:execute(echo {} | awk '{print \$1, \$2}' | head -c -1 | tr -d '\n' | rclip)+accept" \
        --bind="ctrl-c:cancel"
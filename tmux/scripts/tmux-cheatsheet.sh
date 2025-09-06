#!/usr/bin/env bash

# TMUX Cheatsheet Display Script
# Shows a floating popup with beautifully rendered markdown

CHEATSHEET_FILE="$HOME/.dotfiles/tmux/cheatsheet.md"

# Check if cheatsheet file exists
if [[ ! -f "$CHEATSHEET_FILE" ]]; then
    echo "Error: Cheatsheet file not found at $CHEATSHEET_FILE"
    exit 1
fi

# Check if glow is available
if command -v glow >/dev/null 2>&1; then
    # Use glow for beautiful markdown rendering
    # -p: use pager for scrolling
    glow -p "$CHEATSHEET_FILE"
else
    # Fallback to less if glow is not available
    echo "Warning: glow not found, falling back to less"
    less -RXS "$CHEATSHEET_FILE"
fi
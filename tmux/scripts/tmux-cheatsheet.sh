#!/usr/bin/env bash

# TMUX Cheatsheet Display Script
# Shows a floating popup with all tmux key bindings

CHEATSHEET_FILE="$HOME/.dotfiles/tmux/cheatsheet.md"

# Check if cheatsheet file exists
if [[ ! -f "$CHEATSHEET_FILE" ]]; then
    echo "Error: Cheatsheet file not found at $CHEATSHEET_FILE"
    exit 1
fi

# Use less for scrollable viewing
# -R: raw control characters (for colors)
# -X: don't clear screen on exit
# -S: don't wrap long lines
less -RXS "$CHEATSHEET_FILE"
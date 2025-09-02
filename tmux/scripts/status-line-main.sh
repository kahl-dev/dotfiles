#!/usr/bin/env bash
# Simple main tmux status line generator

set -euo pipefail

# Catppuccin Mocha colors
readonly BG="#1e1e2e"
readonly TEXT="#cdd6f4"
readonly BLUE="#89b4fa"
readonly GREEN="#a6e3a1"
readonly YELLOW="#f9e2af"
readonly DIM="#6c7086"
readonly SURFACE="#313244"

# Get CPU usage with icon
cpu_info="#[fg=$YELLOW]⚡ $(~/.dotfiles/tmux/scripts/cpu-simple.sh)#[fg=$TEXT]"

# Get memory usage with icon
mem_info="#[fg=$GREEN]💾 $(~/.dotfiles/tmux/scripts/mem-simple.sh)#[fg=$TEXT]"

# Separator
sep="#[fg=$DIM] │ #[fg=$TEXT]"

# Get hostname display
hostname_display="$(~/.dotfiles/tmux/scripts/hostname-display.sh)"

# Build simple status line  
# Session name is handled by tmux built-in status-left
if [[ -n "$hostname_display" ]]; then
  # Show hostname if not empty
  status_line="${cpu_info}${sep}${mem_info}${sep}#[fg=$DIM]${hostname_display}#[fg=$TEXT] "
else
  # No hostname for default machine - add trailing space for symmetry
  status_line="${cpu_info}${sep}${mem_info} "
fi

echo "$status_line"
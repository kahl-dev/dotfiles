#!/usr/bin/env bash
# Grab a pane from any session/window into the current window via fzf popup.
# Usage: tmux-grab-pane.sh <h|v>
#   h = join horizontally (side by side)
#   v = join vertically (stacked)

set -euo pipefail

direction="${1:-h}"
current_pane="$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}')"

selected=$(
  tmux list-panes -a \
    -F "#{session_name}:#{window_index}.#{pane_index} │ #{window_name} │ #{pane_current_command} │ #{pane_current_path}" \
  | grep -v "^${current_pane} " \
  | fzf \
      --prompt="grab pane (${direction}): " \
      --header="Select pane to pull into current window" \
      --preview='tmux capture-pane -t "$(echo {} | cut -d" " -f1)" -p -e' \
      --preview-window=right:50% \
      --no-sort \
  | cut -d' ' -f1
) || exit 0

[ -z "$selected" ] && exit 0

tmux join-pane "-${direction}" -s "$selected"

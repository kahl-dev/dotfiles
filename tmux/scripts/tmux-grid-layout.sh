#!/usr/bin/env bash
set -euo pipefail

# Arrange panes in a grid with at most N rows
# Usage: tmux-grid-layout.sh <max_rows>

max_rows="${1:-2}"

win_width=$(tmux display-message -p '#{window_width}')
win_height=$(tmux display-message -p '#{window_height}')

mapfile -t pane_ids < <(tmux list-panes -F '#{pane_id}' | sed 's/%//')
pane_count=${#pane_ids[@]}

if (( pane_count <= 1 )); then
  exit 0
fi

if (( max_rows == 1 )); then
  tmux select-layout even-horizontal
  exit 0
fi

if (( pane_count <= max_rows )); then
  tmux select-layout even-vertical
  exit 0
fi

# Grid dimensions
cols=$(( (pane_count + max_rows - 1) / max_rows ))
full_cols=$(( pane_count - cols * (max_rows - 1) ))

# Checksum required by tmux select-layout
layout_checksum() {
  local layout="$1"
  local csum=0
  for (( i = 0; i < ${#layout}; i++ )); do
    local ord
    ord=$(printf '%d' "'${layout:$i:1}")
    csum=$(( ((csum >> 1) | ((csum & 1) << 15)) + ord ))
    csum=$(( csum & 0xFFFF ))
  done
  printf '%04x' "$csum"
}

# Build layout string
# {} = horizontal split (columns side-by-side)
# [] = vertical split (panes stacked)
usable_width=$(( win_width - cols + 1 ))
base_col_width=$(( usable_width / cols ))
extra_width=$(( usable_width - base_col_width * cols ))

pane_idx=0
x=0
layout=""

for (( c = 0; c < cols; c++ )); do
  col_width=$base_col_width
  if (( c < extra_width )); then
    col_width=$(( col_width + 1 ))
  fi

  col_rows=$max_rows
  if (( c >= full_cols )); then
    col_rows=$(( max_rows - 1 ))
  fi

  [[ -n "$layout" ]] && layout+=","

  if (( col_rows == 1 )); then
    layout+="${col_width}x${win_height},${x},0,${pane_ids[$pane_idx]}"
    pane_idx=$(( pane_idx + 1 ))
  else
    usable_height=$(( win_height - col_rows + 1 ))
    base_row_height=$(( usable_height / col_rows ))
    extra_height=$(( usable_height - base_row_height * col_rows ))

    layout+="${col_width}x${win_height},${x},0["
    y=0
    for (( r = 0; r < col_rows; r++ )); do
      row_height=$base_row_height
      if (( r < extra_height )); then
        row_height=$(( row_height + 1 ))
      fi

      (( r > 0 )) && layout+=","
      layout+="${col_width}x${row_height},${x},${y},${pane_ids[$pane_idx]}"
      pane_idx=$(( pane_idx + 1 ))
      y=$(( y + row_height + 1 ))
    done
    layout+="]"
  fi

  x=$(( x + col_width + 1 ))
done

if (( cols > 1 )); then
  layout="${win_width}x${win_height},0,0{${layout}}"
fi

checksum=$(layout_checksum "$layout")
tmux select-layout "${checksum},${layout}"

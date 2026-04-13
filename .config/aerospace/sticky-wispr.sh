#!/bin/bash
CURRENT_WS=$AEROSPACE_FOCUSED_WORKSPACE
/opt/homebrew/bin/aerospace list-windows --all \
  | grep "Wispr Flow" \
  | awk '{print $1}' \
  | while read -r win_id; do
      [ -n "$win_id" ] && /opt/homebrew/bin/aerospace move-node-to-workspace --window-id "$win_id" "$CURRENT_WS" 2>/dev/null
    done

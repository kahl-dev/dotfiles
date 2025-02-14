#!/usr/bin/env bash

if [ "$SENDER" = "aerospace_workspace_change" ]; then
  if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set "$NAME" background.drawing=on
  else
    sketchybar --set "$NAME" background.drawing=off
  fi
fi

# Redraw workspaces and apps on changes to the right display
# if [ "$SENDER" = "space_windows_change" ] || [ "$SENDER" = "front_app_switched" ] || [ "$SENDER" = "display_change" ]; then
#   # echo "$SENDER"
#
#   ITEMS_LIST="$(sketchybar --query bar | jq -r '.items[]')"
#   item_exists() {
#     echo "$ITEMS_LIST" | grep -q "^$1$"
#   }
#
#   # Assign correct Aerospace workspaces
#   while IFS='|' read -r DISPLAY_ID NSSCREEN_ID AERO_ID AERO_NAME; do
#     # echo -e "\n\n$DISPLAY_ID $AERO_ID $AERO_NAME $NSSCREEN_ID"
#
#     # Run aerospace command in a subshell (Prevents breaking while-loop)
#     for sid in $(aerospace list-workspaces --monitor "$AERO_ID" </dev/null); do
#       # echo "Assigning sid: $sid to display $DISPLAY_ID"
#
#       sketchybar --set "space.$sid" \
#         display="$DISPLAY_ID" \
#         label="$sid"
#
#       APPS="$(aerospace list-windows --workspace "$sid" --json </dev/null | jq -r 'map(."app-name") | join(", ")')"
#
#       # Only create the item if there are actual applications and it does not exist yet
#       if [ -n "$APPS" ]; then
#         if ! item_exists "space.$sid.apps"; then
#           sketchybar --add space "space.$sid.apps" left
#         fi
#         sketchybar --set "space.$sid.apps" \
#           display="$DISPLAY_ID" \
#           label="$APPS"
#       else
#         # Only remove the item if it exists
#         if item_exists "space.$sid.apps"; then
#           sketchybar --remove "space.$sid.apps"
#         fi
#       fi
#
#     done
#   done < <("$CONFIG_DIR/match_displays.sh")
#
# fi

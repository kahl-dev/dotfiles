#!/usr/bin/env sh

##### Adding aeropsace layouts #####

# Add the aerospace_workspace_change event we specified in aerospace.toml
sketchybar --add event aerospace_workspace_change

# Create the invisible event item
sketchybar --add item system.aerospace.event left \
  --set system.aerospace.event label="" drawing=off \
  --subscribe system.aerospace.event space_change space_windows_change display_change front_app_switched \
  --set system.aerospace.event script="$CONFIG_DIR/plugins/aerospace.sh"

ITEMS_LIST="$(sketchybar --query bar | jq -r '.items[]')"
item_exists() {
  echo "$ITEMS_LIST" | grep -q "^$1$"
}

# Assign correct Aerospace workspaces
while IFS='|' read -r DISPLAY_ID NSSCREEN_ID AERO_ID AERO_NAME; do
  # echo -e "\n\n$DISPLAY_ID $AERO_ID $AERO_NAME $NSSCREEN_ID"

  # Debigging aerospace/sketchybar mapping
  # sketchybar --add item "aerospace.$DISPLAY_ID" left \
  #   --set "aerospace.$DISPLAY_ID" \
  #     display="$DISPLAY_ID" \
  #     label="$DISPLAY_ID :: $NSSCREEN_ID :: $AERO_ID :: $AERO_NAME"

  # Run aerospace command in a subshell (Prevents breaking while-loop)
  for sid in $(aerospace list-workspaces --monitor "$AERO_ID" </dev/null); do
    # echo "Assigning sid: $sid to display $CG_ID"

    sketchybar --add space "space.$sid" left \
      --set "space.$sid" associated_space="$sid" \
      --subscribe "space.$sid" aerospace_workspace_change  \
      --set "space.$sid" \
      display="$DISPLAY_ID" \
      background.color=0x44ffffff \
      background.corner_radius=5 \
      background.height=20 \
      background.drawing=off \
      label="$sid" \
      click_script="aerospace workspace $sid" \
      script="$CONFIG_DIR/plugins/aerospace.sh $sid"

      APPS="$(aerospace list-windows --workspace "$sid" --json </dev/null | jq -r 'map(."app-name") | join(", ")')"

      # Only create the item if there are actual applications and it does not exist yet
      if [ -n "$APPS" ]; then
        if ! item_exists "space.$sid.apps"; then
          sketchybar --add space "space.$sid.apps" left
        fi
        sketchybar --set "space.$sid.apps" \
          display="$DISPLAY_ID" \
          label="$APPS"
      else
        # Only remove the item if it exists
        if item_exists "space.$sid.apps"; then
          sketchybar --remove "space.$sid.apps"
        fi
      fi

  done
done < <("$CONFIG_DIR/match_displays.sh")

#!/usr/bin/env bash

VERBOSE=0
if [[ "$1" == "--verbose" ]]; then
  VERBOSE=1
fi

# 1️⃣ Get NSScreen IDs and Names (Aerospace Uses These Names)
NSSCREEN_DATA=$(swift -e 'import AppKit; for screen in NSScreen.screens { if let screenID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber { print("\(screenID.intValue)|\(screen.localizedName)") } }')

# Get Sketchybar Data to map the nsscreen id to the sketchybar id
SKETCHYBAR_DATA=$(sketchybar --query displays | jq -r '.[] | "\(.["arrangement-id"])|\(.["DirectDisplayID"])"')

# 3️⃣ Get Aerospac Data to map the name to the nsscreen nam
AERO_MONITORS=$(aerospace list-monitors --format "%{monitor-id}|%{monitor-name}")

# 4️⃣ Print Mappings
if [[ $VERBOSE -eq 1 ]]; then
  echo -e "NSScreen Data:\n$NSSCREEN_DATA\n"
  echo -e "Sketchybar Data:\n$SKETCHYBAR_DATA\n"
  echo -e "Aerospace Monitors:\n$AERO_MONITORS\n"
fi

while IFS='|' read -r SKETCHYBAR_ID SKETCHYBAR_NSSCREEN_ID; do
  NSSCREEN_ID=""
  NSSCREEN_NAME=""
  AERO_ID=""
  AERO_NAME=""

  # Find NSScreen ID
  while IFS='|' read -r ns_id ns_name; do
    if [[ "$ns_id" == "$SKETCHYBAR_NSSCREEN_ID" ]]; then
      NSSCREEN_ID="$ns_id"
      NSSCREEN_NAME="$ns_name"
      break
    fi
  done <<<"$NSSCREEN_DATA"

  # Find Aerospace ID
  while IFS='|' read -r aero_id aero_name; do
    if [[ "$aero_name" == "$NSSCREEN_NAME" ]]; then
      AERO_ID="$aero_id"
      AERO_NAME="$aero_name"
      break
    fi
  done <<<"$AERO_MONITORS"

  # Output based on verbosity
  if [[ -n "$AERO_ID" && -n "$NSSCREEN_ID" ]]; then
    if [[ $VERBOSE -eq 1 ]]; then
      echo "Sketchybar ID: $SKETCHYBAR_ID -> NSScreen ID: $NSSCREEN_ID -> Aerospace ID: $AERO_ID -> Aerospace Names: $AERO_NAME"
    else
      echo "$SKETCHYBAR_ID|$NSSCREEN_ID|$AERO_ID|$AERO_NAME"
    fi
  fi
done <<<"$SKETCHYBAR_DATA"

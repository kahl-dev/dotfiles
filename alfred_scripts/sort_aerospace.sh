#!/usr/bin/env bash

# Set DEBUG to true to enable detailed logging, or false for essential logging only
DEBUG=false

# Function for logging
log() {
  if [ "$DEBUG" = true ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$HOME/aerospace_mgmt.log"
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >>"$HOME/aerospace_mgmt.log"
  fi
}

log "Starting AeroSpace Management Script."

# Check if jq is installed
if ! command -v jq &>/dev/null; then
  log "jq is required but not installed. Install it with 'brew install jq' or visit https://stedolan.github.io/jq/"
  exit 1
fi

# Load configuration file
config_file="config.json"
if [ ! -f "$config_file" ]; then
  log "Configuration file '$config_file' not found. Exiting script."
  exit 1
fi

# Retrieve monitors, windows, and workspaces
monitors_json=$(aerospace list-monitors --json)
windows_json=$(aerospace list-windows --all --json)
workspaces_json=$(aerospace list-workspaces --all --json)
empty_workspaces_json=$(aerospace list-workspaces --empty --monitor all --json)

# Determine the number of monitors
monitor_count=$(echo "$monitors_json" | jq '. | length')
log "Number of monitors detected: $monitor_count"

# Extract and map monitor names and IDs (using Process Substitution)
declare -A monitor_id_mapping
while read -r row; do
  monitor_name=$(echo "$row" | jq -r '.["monitor-name"]')
  monitor_id=$(echo "$row" | jq -r '.["monitor-id"]')
  monitor_id_mapping["$monitor_name"]="$monitor_id"
  log "Monitor ID '$monitor_id' is '$monitor_name'"
done < <(echo "$monitors_json" | jq -rc '.[]')

# Load workspace mappings based on monitor count from config.json
declare -A workspace_monitor_mapping

# Extract workspace assignments from config.json
while IFS=$'\t' read -r workspace monitor_name; do
  workspace_monitor_mapping["$workspace"]="$monitor_name"
  log "Workspace '$workspace' is assigned to monitor '$monitor_name'"
done < <(jq -r --arg mc "$monitor_count" '
    .monitor_mappings[$mc].workspaces | to_entries[] | "\(.key)\t\(.value)"
' "$config_file")

# Identify empty workspaces
declare -A empty_workspaces
while read -r workspace; do
  empty_workspaces["$workspace"]=1
  log "Workspace '$workspace' is empty and will be ignored."
done < <(echo "$empty_workspaces_json" | jq -r '.[].workspace')

# Identify active workspaces (all workspaces minus the empty ones)
declare -A active_workspaces
while read -r workspace; do
  if [[ -z "${empty_workspaces["$workspace"]}" ]]; then
    active_workspaces["$workspace"]=1
    log "Workspace '$workspace' is active (has windows)."
  else
    log "Workspace '$workspace' is empty and will be ignored."
  fi
done < <(echo "$workspaces_json" | jq -r '.[].workspace')

log "Active workspaces (with windows): ${!active_workspaces[@]}"

log "Assigning workspaces to monitors..."

# Function to move workspaces to monitors
move_workspace_to_monitor() {
  local workspace=$1
  local monitor_name=$2
  local monitor_id="${monitor_id_mapping["$monitor_name"]}"

  if [ -z "$monitor_id" ]; then
    log "Monitor '$monitor_name' not found. Skipping workspace '$workspace'."
    return
  fi

  log "Checking if workspace '$workspace' is already on monitor '$monitor_name' (ID: $monitor_id)."

  # Check if the workspace is already on the target monitor
  current_workspaces=$(aerospace list-workspaces --monitor "$monitor_id" --json)
  if echo "$current_workspaces" | jq -e --arg ws "$workspace" '.[] | select(.workspace == $ws)' >/dev/null; then
    log "Workspace '$workspace' is already on monitor '$monitor_name'."
    return
  fi

  log "Workspace '$workspace' is not on monitor '$monitor_name'. Moving now."

  # Move workspace to 'next' and check after each step
  local max_attempts=10
  local attempts=0

  while [ "$attempts" -lt "$max_attempts" ]; do
    # Move workspace to 'next'
    aerospace move-workspace-to-monitor --workspace "$workspace" --wrap-around next
    sleep 0.2 # Short pause to allow the change to take effect

    # Check if the workspace is now on the target monitor
    current_workspaces=$(aerospace list-workspaces --monitor "$monitor_id" --json)
    if echo "$current_workspaces" | jq -e --arg ws "$workspace" '.[] | select(.workspace == $ws)' >/dev/null; then
      log "Successfully moved workspace '$workspace' to monitor '$monitor_name'."
      return
    fi

    attempts=$((attempts + 1))
    log "Attempt $attempts: Workspace '$workspace' may now be on another monitor."
  done

  log "Error: Workspace '$workspace' could not be moved to monitor '$monitor_name' after $max_attempts attempts."
}

# Move workspaces to monitors, only if they are active
for workspace in "${!workspace_monitor_mapping[@]}"; do
  if [[ -n "${active_workspaces["$workspace"]}" ]]; then
    monitor_name="${workspace_monitor_mapping["$workspace"]}"
    move_workspace_to_monitor "$workspace" "$monitor_name"
  else
    log "Workspace '$workspace' has no windows. Skipping."
  fi
done

# Assign applications to workspaces
declare -A app_workspace_mapping
# Extract app assignments from config.json
while read -r entry; do
  app_name=$(echo "$entry" | jq -r '.key')
  target_workspace=$(echo "$entry" | jq -r '.value')
  app_workspace_mapping["$app_name"]="$target_workspace"
  log "Application '$app_name' is assigned to workspace '$target_workspace'"
done < <(jq -c '.app_mappings | to_entries[]' "$config_file")

log "Assigning applications to workspaces..."

# Move windows to their assigned workspaces
echo "$windows_json" | jq -c '.[]' | while read -r window; do
  window_id=$(echo "$window" | jq -r '.["window-id"]')
  app_name=$(echo "$window" | jq -r '.["app-name"]')
  target_workspace="${app_workspace_mapping["$app_name"]}"

  if [[ -n "$target_workspace" && -n "${active_workspaces["$target_workspace"]}" ]]; then
    # Check if the window is already in the target workspace
    windows_in_target_workspace=$(aerospace list-windows --workspace "$target_workspace" --json)

    # Verify if the window already exists in the target workspace
    if echo "$windows_in_target_workspace" | jq -e --arg id "$window_id" '.[] | select(.["window-id"] == ($id | tonumber))' >/dev/null; then
      log "Window '$app_name' (ID: $window_id) is already in the target workspace '$target_workspace'. Skipping."
      continue
    fi

    # Move the window if it is not in the target workspace
    log "Moving '$app_name' (Window ID: $window_id) to workspace '$target_workspace'"
    aerospace move-node-to-workspace --fail-if-noop --window-id "$window_id" "$target_workspace"

    if [ $? -eq 0 ]; then
      log "Successfully moved '$app_name' to workspace '$target_workspace'."
    else
      log "Error moving '$app_name' to workspace '$target_workspace'."
    fi
  else
    log "Workspace '$target_workspace' for application '$app_name' is either not defined or has no windows. Skipping."
  fi
done

log "AeroSpace Management Script completed."

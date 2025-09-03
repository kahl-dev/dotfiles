#!/usr/bin/env bash
# Claude session cleanup - Remove entries for killed tmux sessions, windows, and panes
# Called by tmux hooks when sessions, windows, or panes are closed

set -euo pipefail

readonly SCRIPT_NAME=$(basename "$0")
readonly STATUS_FILE="$HOME/.claude/sessions/status.json"
readonly LOG_FILE="$HOME/.claude/sessions/tracker.log"

# Logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$SCRIPT_NAME] $*" >> "$LOG_FILE"
}

# Exit if no status file exists
if [[ ! -f "$STATUS_FILE" ]]; then
  log "No status file found - nothing to clean up"
  exit 0
fi

# Check dependencies
if ! command -v jq >/dev/null 2>&1; then
  log "ERROR: jq is required but not installed"
  exit 1
fi

if ! command -v tmux >/dev/null 2>&1; then
  log "ERROR: tmux is required but not installed"
  exit 1
fi

# Get all current tmux sessions, windows, and panes
get_active_tmux_locations() {
  # Return format: session:window.pane (one per line)
  tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}" 2>/dev/null || true
}

# Clean up status file
cleanup_status_file() {
  local status_json="$1"
  local active_locations="$2"
  
  # Create a temporary array of active locations for jq processing
  local active_array
  active_array=$(echo "$active_locations" | jq -R -s 'split("\n") | map(select(length > 0))')
  
  # Filter status.json to only include entries that exist in active tmux locations
  echo "$status_json" | jq --argjson active "$active_array" '
    .sessions = [
      .sessions[] | 
      . as $session |
      ($session.tmux_session + ":" + ($session.tmux_window | tostring) + "." + ($session.tmux_pane | tostring)) as $location |
      select($active | index($location))
    ]
  '
}

# Main cleanup function
main() {
  log "Starting Claude session cleanup"
  
  # Read current status
  local current_status
  current_status=$(cat "$STATUS_FILE" 2>/dev/null || echo '{"sessions":[]}')
  
  # Get count of sessions before cleanup
  local before_count
  before_count=$(echo "$current_status" | jq '.sessions | length')
  
  # Get active tmux locations
  local active_locations
  active_locations=$(get_active_tmux_locations)
  
  if [[ -z "$active_locations" ]]; then
    log "No active tmux sessions found - clearing all Claude sessions"
    echo '{"sessions": []}' > "$STATUS_FILE"
    log "Cleared all sessions (no active tmux sessions)"
    return 0
  fi
  
  # Clean up status file
  local cleaned_status
  cleaned_status=$(cleanup_status_file "$current_status" "$active_locations")
  
  # Get count after cleanup
  local after_count
  after_count=$(echo "$cleaned_status" | jq '.sessions | length')
  
  # Write cleaned status back to file
  echo "$cleaned_status" > "$STATUS_FILE"
  
  # Log results
  local removed_count=$((before_count - after_count))
  if [[ $removed_count -gt 0 ]]; then
    log "Cleanup completed: removed $removed_count stale session entries (${before_count} -> ${after_count})"
  else
    log "Cleanup completed: no stale sessions found ($before_count entries remain valid)"
  fi
  
  # Trigger tmux status refresh
  tmux refresh-client -S 2>/dev/null || true
}

# Run main function
main "$@"
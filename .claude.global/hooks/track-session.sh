#!/usr/bin/env bash
# Claude Code Session Tracker
# Tracks Claude Code sessions in tmux for dashboard monitoring

set -euo pipefail

readonly SCRIPT_NAME=$(basename "$0")
readonly STATUS_FILE="$HOME/.claude/sessions/status.json"
readonly LOG_FILE="$HOME/.claude/sessions/tracker.log"

# Ensure directories exist
mkdir -p "$(dirname "$STATUS_FILE")" "$(dirname "$LOG_FILE")"

# Logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$SCRIPT_NAME] $*" >> "$LOG_FILE"
}

# Error handling
error_exit() {
  log "ERROR: $*"
  exit 1
}

# Get current timestamp in ISO format
get_timestamp() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

# Detect tmux session info
get_tmux_info() {
  if [[ -z "${TMUX:-}" ]]; then
    log "WARN: Not running in tmux session"
    echo "null,null,null"
    return
  fi
  
  local tmux_session tmux_window tmux_pane
  
  # Get session name
  tmux_session=$(tmux display-message -p '#S' 2>/dev/null || echo "unknown")
  
  # Get window index
  tmux_window=$(tmux display-message -p '#I' 2>/dev/null || echo "0")
  
  # Get pane index
  tmux_pane=$(tmux display-message -p '#P' 2>/dev/null || echo "0")
  
  echo "$tmux_session,$tmux_window,$tmux_pane"
}

# Initialize status file if it doesn't exist
init_status_file() {
  if [[ ! -f "$STATUS_FILE" ]]; then
    echo '{"sessions": []}' > "$STATUS_FILE"
    log "Initialized status file: $STATUS_FILE"
  fi
}

# Read current status file
read_status() {
  if [[ ! -f "$STATUS_FILE" ]]; then
    init_status_file
  fi
  cat "$STATUS_FILE"
}

# Write status file
write_status() {
  local content="$1"
  echo "$content" > "$STATUS_FILE"
}

# Find existing session in JSON
find_session() {
  local session="$1"
  local window="$2" 
  local pane="$3"
  local status_json="$4"
  
  echo "$status_json" | jq -r --arg session "$session" --arg window "$window" --arg pane "$pane" '
    .sessions[] | 
    select(.tmux_session == $session and .tmux_window == ($window | tonumber) and .tmux_pane == ($pane | tonumber)) |
    @base64'
}

# Add or update session
update_session() {
  local action="$1"
  local session="$2"
  local window="$3"
  local pane="$4"
  local status_json="$5"
  
  local timestamp
  timestamp=$(get_timestamp)
  
  local project_dir="${PWD:-/unknown}"
  local claude_session_id="${CLAUDE_SESSION_ID:-unknown}"
  
  # Determine status based on action
  local new_status
  case "$action" in
    start)      new_status="starting" ;;
    activity)   new_status="working" ;;
    permission) new_status="asking" ;;
    stop)       
      # Check for stale "asking" status and clean it up
      local existing_session
      existing_session=$(find_session "$session" "$window" "$pane" "$status_json")
      if [[ "$existing_session" != "null" && -n "$existing_session" ]]; then
        local current_status
        current_status=$(echo "$status_json" | jq -r --arg session "$session" --arg window "$window" --arg pane "$pane" '
          .sessions[] | 
          select(.tmux_session == $session and .tmux_window == ($window | tonumber) and .tmux_pane == ($pane | tonumber)) |
          .status')
        
        if [[ "$current_status" == "asking" ]]; then
          local last_activity
          last_activity=$(echo "$status_json" | jq -r --arg session "$session" --arg window "$window" --arg pane "$pane" '
            .sessions[] | 
            select(.tmux_session == $session and .tmux_window == ($window | tonumber) and .tmux_pane == ($pane | tonumber)) |
            .last_activity')
          
          # Check if asking status is older than 30 seconds
          local current_time stale_threshold
          current_time=$(get_timestamp)
          stale_threshold=$(date -u -d '30 seconds ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || \
                           date -u -j -v-30S '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || \
                           echo "1970-01-01T00:00:00Z")
          
          if [[ "$last_activity" < "$stale_threshold" ]]; then
            log "Cleaning up stale asking status for $session:$window.$pane (last activity: $last_activity)"
          fi
        fi
      fi
      new_status="waiting" ;;
    end)        new_status="idle" ;;
    *)          new_status="unknown" ;;
  esac
  
  # Check if session exists
  local existing_session
  existing_session=$(find_session "$session" "$window" "$pane" "$status_json")
  
  if [[ "$existing_session" != "null" && -n "$existing_session" ]]; then
    # Update existing session
    echo "$status_json" | jq --arg session "$session" \
                              --arg window "$window" \
                              --arg pane "$pane" \
                              --arg status "$new_status" \
                              --arg timestamp "$timestamp" \
                              --arg project_dir "$project_dir" \
                              --arg claude_session_id "$claude_session_id" '
      .sessions = (.sessions | map(
        if (.tmux_session == $session and .tmux_window == ($window | tonumber) and .tmux_pane == ($pane | tonumber))
        then . + {
          "status": $status,
          "last_activity": $timestamp,
          "project_dir": $project_dir,
          "claude_session_id": $claude_session_id
        }
        else .
        end
      ))
    '
  else
    # Add new session
    echo "$status_json" | jq --arg session "$session" \
                              --arg window "$window" \
                              --arg pane "$pane" \
                              --arg status "$new_status" \
                              --arg timestamp "$timestamp" \
                              --arg project_dir "$project_dir" \
                              --arg claude_session_id "$claude_session_id" '
      .sessions += [{
        "tmux_session": $session,
        "tmux_window": ($window | tonumber),
        "tmux_pane": ($pane | tonumber),
        "project_dir": $project_dir,
        "status": $status,
        "last_activity": $timestamp,
        "claude_session_id": $claude_session_id,
        "created_at": $timestamp
      }]
    '
  fi
}

# Clean up old sessions (older than 24 hours)
cleanup_old_sessions() {
  local status_json="$1"
  local cutoff_time
  cutoff_time=$(date -u -d '24 hours ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || \
                date -u -j -v-24H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || \
                echo "1970-01-01T00:00:00Z")
  
  echo "$status_json" | jq --arg cutoff "$cutoff_time" '
    .sessions = (.sessions | map(select(.last_activity > $cutoff)))
  '
}

# Main function
main() {
  local action="${1:-activity}"
  
  log "Started with action: $action"
  
  # Get tmux info
  local tmux_info
  tmux_info=$(get_tmux_info)
  
  IFS=',' read -r tmux_session tmux_window tmux_pane <<< "$tmux_info"
  
  if [[ "$tmux_session" == "null" ]]; then
    log "WARN: Skipping tracking - not in tmux session"
    exit 0
  fi
  
  log "Tmux info: session=$tmux_session, window=$tmux_window, pane=$tmux_pane"
  
  # Initialize status file
  init_status_file
  
  # Read current status
  local current_status
  current_status=$(read_status)
  
  # Update session
  local updated_status
  updated_status=$(update_session "$action" "$tmux_session" "$tmux_window" "$tmux_pane" "$current_status")
  
  # Clean up old sessions
  local cleaned_status
  cleaned_status=$(cleanup_old_sessions "$updated_status")
  
  # Write back to file
  write_status "$cleaned_status"
  
  # Trigger dynamic auto-switcher to update tmux status lines (with load protection)
  if [[ -x "$HOME/.dotfiles/tmux/scripts/claude-status-autorule.sh" ]]; then
    # Check system load before spawning background process
    local current_load
    current_load=$(uptime 2>/dev/null | sed -E 's/.*load.averages?:[[:space:]]*([0-9]+\.[0-9]+).*/\1/' || echo "0.00")
    
    # Only spawn if load is reasonable (< 8.0) and not already running
    if command -v bc >/dev/null 2>&1 && (( $(echo "$current_load < 8.0" | bc) )) && ! pgrep -f "claude-status-autorule.sh" >/dev/null 2>&1; then
      "$HOME/.dotfiles/tmux/scripts/claude-status-autorule.sh" &
    else
      log "SKIP: Skipping claude-status-autorule.sh due to high load ($current_load) or already running"
    fi
  fi
  
  log "Successfully updated session status: $action for $tmux_session:$tmux_window.$tmux_pane"
}

# Check dependencies
command -v jq >/dev/null 2>&1 || error_exit "jq is required but not installed"
command -v tmux >/dev/null 2>&1 || error_exit "tmux is required but not installed"

# Run main function
main "$@"
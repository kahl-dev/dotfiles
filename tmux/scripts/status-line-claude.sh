#!/usr/bin/env bash
# Claude sessions status line with smart multi-Claude indicator

set -euo pipefail

# Status file path
STATUS_FILE="$HOME/.claude/sessions/status.json"

# Check if status file exists
if [[ ! -f "$STATUS_FILE" ]]; then
  exit 0
fi

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

# Try to read sessions count
session_count=$(jq -r '.sessions | length' "$STATUS_FILE" 2>/dev/null || echo "0")

# If no sessions, return empty (triggers 1-line mode)
if [[ "$session_count" -eq 0 ]]; then
  exit 0
fi

# Validate sessions against actual tmux sessions (fallback cleanup)
# This ensures we don't display entries for non-existent sessions/windows/panes
validate_sessions() {
  local status_json="$1"
  
  # Get active tmux locations
  local active_locations
  active_locations=$(tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}" 2>/dev/null || echo "")
  
  if [[ -z "$active_locations" ]]; then
    # No active tmux sessions, return empty
    echo '{"sessions": []}'
    return
  fi
  
  # Create active locations array for jq
  local active_array
  active_array=$(echo "$active_locations" | jq -R -s 'split("\n") | map(select(length > 0))')
  
  # Filter sessions to only include valid ones
  echo "$status_json" | jq --argjson active "$active_array" '
    .sessions = [
      .sessions[] | 
      . as $session |
      ($session.tmux_session + ":" + ($session.tmux_window | tostring) + "." + ($session.tmux_pane | tostring)) as $location |
      select($active | index($location))
    ]
  '
}

# Validate sessions before processing
status_json=$(cat "$STATUS_FILE" 2>/dev/null || echo '{"sessions":[]}')
validated_status_json=$(validate_sessions "$status_json")

# Update session count after validation
session_count=$(echo "$validated_status_json" | jq -r '.sessions | length' 2>/dev/null || echo "0")

# If no valid sessions after validation, return empty (triggers 1-line mode)
if [[ "$session_count" -eq 0 ]]; then
  exit 0
fi

# Check for active sessions (working, asking, starting within 5 minutes)
# If no active sessions exist, return empty to trigger 1-line mode
cutoff_5min=$(date -u -d '5 minutes ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -j -v-5M '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo '1970-01-01T00:00:00Z')

active_sessions_count=$(echo "$validated_status_json" | jq -r --arg cutoff "$cutoff_5min" '
  [.sessions | group_by(.project_dir) | .[] | 
    select([.[] | select(.last_activity > $cutoff and (.status == "working" or .status == "asking" or .status == "starting"))] | length > 0)
  ] | length
' 2>/dev/null || echo "0")

# If no active sessions, return empty (triggers 1-line mode)
if [[ "$active_sessions_count" -eq 0 ]]; then
  exit 0
fi

# Get current tmux session and working directory
current_session=$(tmux display-message -p '#S' 2>/dev/null || echo "")
current_path=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null || echo "")

# Build sessions list with new logic
sessions_info=""
session_parts=()

# Use the 5-minute cutoff calculated above

# Smart project path normalization - treat parent/child directories as same project
normalize_project_paths() {
  local json="$1"
  echo "$json" | jq '
    # Add normalized_project_dir field based on path similarity
    .sessions |= map(
      . + {
        "normalized_project_dir": (
          # For paths ending in common subdirs, use parent directory
          if (.project_dir | test("/(frontend|backend|src|app|web|client|server)$")) then
            (.project_dir | gsub("/(?:frontend|backend|src|app|web|client|server)$"; ""))
          else
            .project_dir
          end
        )
      }
    )
  '
}

# Clean up stale "asking" states globally (sessions stuck in asking mode)
cleanup_stale_asking() {
  local json="$1"
  local stale_threshold
  stale_threshold=$(date -u -d '30 seconds ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -j -v-30S '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo '1970-01-01T00:00:00Z')
  
  echo "$json" | jq --arg threshold "$stale_threshold" '
    .sessions = (.sessions | map(
      if (.status == "asking" and .last_activity < $threshold) then
        . + {"status": "waiting"}
      else
        .
      end
    ))
  '
}

# Clean up stale asking states before processing
cleaned_json=$(cleanup_stale_asking "$validated_status_json")

# Update the status file with cleaned data
if [[ "$cleaned_json" != "$validated_status_json" ]]; then
  echo "$cleaned_json" > "$STATUS_FILE" 2>/dev/null || true
fi

# Normalize paths and group by normalized project directory  
# Use the cleaned status JSON
normalized_json=$(normalize_project_paths "$cleaned_json")

sessions_data=$(echo "$normalized_json" | jq -r --arg cutoff "$cutoff_5min" '
  [.sessions | group_by(.normalized_project_dir) | .[] | 
    {
      session: .[0].tmux_session,
      project_dir: .[0].normalized_project_dir,
      original_dirs: [.[].project_dir] | unique,
      most_recent_status: (sort_by(.last_activity) | reverse | .[0].status),
      latest_activity: ([.[].last_activity] | max),
      active_claude_count: [.[] | select(.last_activity > $cutoff and (.status == "working" or .status == "asking" or .status == "starting"))] | length
    }
  ] | sort_by(.latest_activity) | reverse
' 2>/dev/null)

if [[ -n "$sessions_data" ]]; then
  while IFS= read -r line; do
    session_name=$(echo "$line" | jq -r '.session')
    session_project=$(echo "$line" | jq -r '.project_dir')
    session_status=$(echo "$line" | jq -r '.most_recent_status')
    active_count=$(echo "$line" | jq -r '.active_claude_count')
    
    # Map status to emoji
    case "$session_status" in
      "starting") icon="🚀" ;;
      "working") icon="🧠" ;;
      "asking") icon="🤔" ;;
      "waiting") icon="⏳" ;;
      "idle") icon="💤" ;;
      *) icon="✅" ;;
    esac
    
    # Add + indicator if multiple active Claude instances
    multi_indicator=""
    if [[ "$active_count" -gt 1 ]]; then
      multi_indicator="+"
    fi
    
    # Check if this is the current session - match by name first, then by project directory
    is_current_session=false
    if [[ "$session_name" == "$current_session" ]] || [[ "$session_project" == "$current_path" ]]; then
      is_current_session=true
    fi
    
    # For display, use current tmux session name if this matches current path
    display_name="$session_name"
    if [[ "$session_project" == "$current_path" && "$session_name" != "$current_session" ]]; then
      display_name="$current_session"
    fi
    
    # Highlight current session like active window
    if [[ "$is_current_session" == "true" ]]; then
      session_parts+=("#[fg=#89b4fa] $display_name:$icon$multi_indicator")
    else
      session_parts+=("#[fg=#6c7086] $display_name:$icon$multi_indicator")
    fi
  done <<< "$(echo "$sessions_data" | jq -c '.[]')"
fi

# Join session parts
if [[ ${#session_parts[@]} -gt 0 ]]; then
  sessions_info=$(IFS=' ' ; echo "${session_parts[*]}")
else
  sessions_info="No active sessions"
fi

# Count total active sessions (any session with recent activity)
total_active_count=$(echo "$sessions_data" | jq -r '[.[] | select(.active_claude_count > 0)] | length' 2>/dev/null || echo "0")

# Output the Sessions status line
echo "#[fg=#89b4fa] Sessions#[fg=#313244]:$sessions_info #[fg=#6c7086]│ #[fg=#cdd6f4]$total_active_count active"
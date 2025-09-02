#!/usr/bin/env bash
# Claude sessions status line showing individual session names with status icons

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

# Get current tmux session and working directory
current_session=$(tmux display-message -p '#S' 2>/dev/null || echo "")
current_path=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null || echo "")

# Build sessions list with individual names and status icons
sessions_info=""
session_parts=()

# Get unique sessions (group by project_dir to handle renames)
unique_sessions=$(jq -r --arg cutoff "$(date -u -d '5 minutes ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -j -v-5M '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo '1970-01-01T00:00:00Z')" '[.sessions | group_by(.project_dir) | .[] | {session: .[0].tmux_session, project_dir: .[0].project_dir, status: [.[] | select(.last_activity > $cutoff) | .status] | if length == 0 then "idle" elif any(. == "asking") then "asking" elif any(. == "working") then "working" elif any(. == "waiting") then "waiting" else "idle" end, latest_activity: ([.[].last_activity] | max)}] | sort_by(.latest_activity) | reverse' "$STATUS_FILE" 2>/dev/null)

if [[ -n "$unique_sessions" ]]; then
  while IFS= read -r line; do
    session_name=$(echo "$line" | jq -r '.session')
    session_project=$(echo "$line" | jq -r '.project_dir')
    session_status=$(echo "$line" | jq -r '.status')
    
    # Map status to emoji
    case "$session_status" in
      "starting") icon="🚀" ;;
      "working") icon="🧠" ;;
      "asking") icon="🤔" ;;
      "waiting") icon="⏳" ;;
      "idle") icon="💤" ;;
      *) icon="✅" ;;
    esac
    
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
      session_parts+=("#[fg=#89b4fa] $display_name:$icon")
    else
      session_parts+=("#[fg=#6c7086] $display_name:$icon")
    fi
  done <<< "$(echo "$unique_sessions" | jq -c '.[]')"
fi

# Join session parts
if [[ ${#session_parts[@]} -gt 0 ]]; then
  sessions_info=$(IFS=' ' ; echo "${session_parts[*]}")
else
  sessions_info="No active sessions"
fi

# Count active sessions (with working/waiting status) - group by project_dir like we do above
active_count=$(jq -r '[.sessions | group_by(.project_dir) | .[] | select(any(.[].status; . == "working" or . == "waiting"))] | length' "$STATUS_FILE" 2>/dev/null || echo "0")

# Output the Sessions status line
echo "#[fg=#89b4fa] Sessions#[fg=#313244]:$sessions_info #[fg=#6c7086]│ #[fg=#cdd6f4]$active_count active"
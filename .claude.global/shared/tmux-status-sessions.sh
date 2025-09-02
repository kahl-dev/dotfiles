#!/usr/bin/env bash
# Tmux Status Line Generator - Shows all sessions with Claude status
# Designed to be called from tmux status-format

readonly STATUS_FILE="$HOME/.claude/sessions/status.json"

# Status symbols
get_status_symbol() {
  case "$1" in
    starting)         echo "🚀" ;;
    working)          echo "🧠" ;;
    waiting)          echo "⏳" ;;
    needs_permission) echo "🔐" ;;
    idle)             echo "💤" ;;
    *)                echo "" ;;
  esac
}

# Status color codes for tmux
get_status_color() {
  case "$1" in
    starting)         echo "#[fg=blue]" ;;
    working)          echo "#[fg=yellow,bold]" ;;
    waiting)          echo "#[fg=green,bold]" ;;
    needs_permission) echo "#[fg=red,bold]" ;;
    idle)             echo "#[fg=colour240]" ;;
    *)                echo "#[fg=default]" ;;
  esac
}

# Read status file
read_status() {
  if [[ ! -f "$STATUS_FILE" ]]; then
    echo '{"sessions": []}'
    return
  fi
  cat "$STATUS_FILE"
}

# Get current session
get_current_session() {
  tmux display-message -p '#S' 2>/dev/null || echo ""
}

# Get all tmux sessions
get_all_tmux_sessions() {
  tmux list-sessions -F "#{session_name}" 2>/dev/null || echo ""
}

# Find Claude status for a session
find_claude_status() {
  local session="$1"
  local status_json="$2"
  
  if command -v jq >/dev/null 2>&1; then
    echo "$status_json" | jq -r --arg session "$session" '
      .sessions[] | 
      select(.tmux_session == $session) |
      .status' 2>/dev/null | head -1 || echo ""
  else
    echo ""
  fi
}

# Generate status line
generate_status_line() {
  local status_json
  status_json=$(read_status)
  
  local current_session
  current_session=$(get_current_session)
  
  local all_sessions
  all_sessions=$(get_all_tmux_sessions)
  
  local output=""
  local claude_count=0
  local waiting_count=0
  
  # Build session list
  while IFS= read -r session; do
    if [[ -n "$session" ]]; then
      local claude_status
      claude_status=$(find_claude_status "$session" "$status_json")
      
      # Add separator if not first item
      [[ -n "$output" ]] && output+=" #[fg=colour240]│ "
      
      # Current session indicator
      if [[ "$session" == "$current_session" ]]; then
        output+="#[fg=cyan,bold]"
      else
        output+="#[fg=default]"
      fi
      
      # Add session name (clickable via mouse handler)
      output+="$session"
      
      # Add Claude status if present
      if [[ -n "$claude_status" && "$claude_status" != "null" ]]; then
        local symbol color
        symbol=$(get_status_symbol "$claude_status")
        color=$(get_status_color "$claude_status")
        output+=" ${color}${symbol}"
        ((claude_count++))
        [[ "$claude_status" == "waiting" ]] && ((waiting_count++))
      fi
      
      output+="#[fg=default]"
    fi
  done <<< "$all_sessions"
  
  # Add summary at the end
  if (( waiting_count > 0 )); then
    output+=" #[fg=green,bold] ⏳ Ready: $waiting_count#[fg=default]"
  elif (( claude_count > 0 )); then
    output+=" #[fg=colour240] Claude: $claude_count#[fg=default]"
  fi
  
  echo "$output"
}

# Main
main() {
  generate_status_line
}

main "$@"
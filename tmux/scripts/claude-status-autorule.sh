#!/usr/bin/env bash
# Dynamic tmux status line auto-switcher for Claude sessions
# Switches between 1-line and 2-line status based on active Claude sessions

set -euo pipefail

# Status file path
readonly STATUS_FILE="$HOME/.claude/sessions/status.json"

# Check if required tools are available
if ! command -v jq >/dev/null 2>&1 || ! command -v tmux >/dev/null 2>&1; then
  exit 0
fi

# Check if status file exists
if [[ ! -f "$STATUS_FILE" ]]; then
  exit 0
fi

# Get current tmux status setting
current_status=$(tmux show-options -gv status 2>/dev/null || echo "1")

# Calculate active sessions count (same logic as status-line-claude.sh)
cutoff_5min=$(date -u -d '5 minutes ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -j -v-5M '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo '1970-01-01T00:00:00Z')

# Count active Claude sessions (working, asking, starting within 5 minutes)
active_count=$(jq -r --arg cutoff "$cutoff_5min" '
  [.sessions | group_by(.project_dir) | .[] | 
    select([.[] | select(.last_activity > $cutoff and (.status == "working" or .status == "asking" or .status == "starting"))] | length > 0)
  ] | length
' "$STATUS_FILE" 2>/dev/null || echo "0")

# Determine desired status lines
if [[ "$active_count" -gt 0 ]]; then
  desired_status="2"
else  
  desired_status="1"
fi

# Only change if necessary (avoid unnecessary tmux operations)
if [[ "$current_status" != "$desired_status" ]]; then
  tmux set-option -g status "$desired_status" 2>/dev/null || true
fi

exit 0
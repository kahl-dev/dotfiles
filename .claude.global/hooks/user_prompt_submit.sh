#!/bin/bash
# UserPromptSubmit hook - captures user prompts and stores them in session files
# Inspired by disler's claude-code-hooks-mastery
# Security: Input validation and sanitization implemented

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Maximum lengths for security
readonly MAX_PROMPT_LENGTH=10000
readonly MAX_SESSION_ID_LENGTH=100

input=$(cat)

# Validate input is not empty
if [ -z "$input" ]; then
  exit 0
fi

# Extract session_id and prompt from JSON input with validation
if command -v jq >/dev/null 2>&1; then
  session_id=$(echo "$input" | jq -r '.session_id // "unknown"' 2>/dev/null)
  prompt=$(echo "$input" | jq -r '.prompt // ""' 2>/dev/null)
else
  # Fallback if jq is not available - exit safely
  exit 0
fi

# Validate session_id format (alphanumeric, hyphens, underscores only)
if ! [[ "$session_id" =~ ^[a-zA-Z0-9_-]+$ ]] || [ ${#session_id} -gt $MAX_SESSION_ID_LENGTH ]; then
  session_id="unknown"
fi

# Skip if no valid prompt or prompt too long
if [ -z "$prompt" ] || [ "$prompt" = "null" ] || [ ${#prompt} -gt $MAX_PROMPT_LENGTH ]; then
  exit 0
fi

# Ensure sessions directory exists
sessions_dir="$HOME/.claude/data/sessions"
mkdir -p "$sessions_dir"

# Session file path
session_file="$sessions_dir/${session_id}.json"

# Load existing session data or create new
if [ -f "$session_file" ]; then
  if command -v jq >/dev/null 2>&1; then
    # Read existing prompts array
    existing_prompts=$(jq -r '.prompts // [] | @json' "$session_file" 2>/dev/null || echo '[]')
  else
    existing_prompts='[]'
  fi
else
  existing_prompts='[]'
fi

# Create updated session data using jq (we already validated jq exists above)
# Add new prompt to the array with proper JSON escaping
new_session_data=$(jq -n \
  --arg session_id "$session_id" \
  --arg prompt "$prompt" \
  --argjson existing_prompts "$existing_prompts" \
  '{
    session_id: $session_id,
    prompts: ($existing_prompts + [$prompt])
  }')

# Write to session file with error handling
if ! echo "$new_session_data" > "$session_file"; then
  # If write fails, exit gracefully without blocking Claude
  exit 0
fi

# Log the prompt with proper escaping and rotation
log_dir="$HOME/.claude/logs"
mkdir -p "$log_dir"
log_file="$log_dir/user_prompt_submit.log"

# Rotate log if it gets too large (>10MB)
if [ -f "$log_file" ]; then
  file_size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0)
  if [ "$file_size" -gt 10485760 ]; then
    mv "$log_file" "${log_file}.old" 2>/dev/null || true
  fi
fi

# Log entry with proper JSON encoding to prevent injection
log_timestamp=$(date '+%Y-%m-%d %H:%M:%S')
jq -n \
  --arg timestamp "$log_timestamp" \
  --arg session_id "$session_id" \
  --arg prompt "$prompt" \
  '{timestamp: $timestamp, session_id: $session_id, prompt: $prompt}' >> "$log_file" 2>/dev/null || true

# Exit successfully to allow prompt to proceed
exit 0
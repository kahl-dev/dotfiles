#!/bin/bash

# File Type Tracker Hook
# Tracks file extensions that Claude edits for later linter analysis

set -u

# Read hook input from stdin
cat > /tmp/hook-stdin.json

# File to store tracking data
DATA_FILE="$HOME/.claude/user-data/file-types.json"

# Get current timestamp in ISO format
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Extract file extension from path
get_extension() {
    local file_path="$1"
    local filename
    filename="$(basename "$file_path")"
    
    # Handle files with no extension
    if [[ "$filename" != *.* ]]; then
        echo "no-extension"
        return
    fi
    
    # Get the extension (including the dot)
    echo ".${filename##*.}"
}

# Create user-data directory if it doesn't exist
mkdir -p "$(dirname "$DATA_FILE")"

# Initialize data file if it doesn't exist
if [[ ! -f "$DATA_FILE" ]]; then
    cat > "$DATA_FILE" << 'EOF'
{
  "tracking_started": "",
  "last_updated": "",
  "file_types": {}
}
EOF
fi

# Read JSON input from Claude hook system
if [[ -f /tmp/hook-stdin.json ]]; then
    HOOK_INPUT="$(cat /tmp/hook-stdin.json)"
elif [[ -n "${1:-}" ]]; then
    HOOK_INPUT="$1"
else
    # Read from stdin if no argument provided
    HOOK_INPUT="$(cat)"
fi

# Extract tool name and file path from hook input
TOOL_NAME="$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty')"
FILE_PATH="$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // empty')"

# Only track Write, Edit, and MultiEdit operations
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "MultiEdit" ]]; then
    exit 0
fi

# Skip if no file path found
if [[ -z "$FILE_PATH" || "$FILE_PATH" == "null" ]]; then
    exit 0
fi

# Get file extension
EXTENSION="$(get_extension "$FILE_PATH")"
CURRENT_TIME="$(get_timestamp)"

# Update the JSON file
jq --arg ext "$EXTENSION" \
   --arg file_path "$FILE_PATH" \
   --arg current_time "$CURRENT_TIME" '
   # Set tracking_started if empty
   if .tracking_started == "" then
     .tracking_started = $current_time
   else . end |
   
   # Update last_updated
   .last_updated = $current_time |
   
   # Initialize extension if it doesn'\''t exist
   if .file_types[$ext] == null then
     .file_types[$ext] = {
       "count": 0,
       "first_seen": $current_time,
       "last_seen": $current_time,
       "recent_files": []
     }
   else . end |
   
   # Update count and last_seen
   .file_types[$ext].count += 1 |
   .file_types[$ext].last_seen = $current_time |
   
   # Add file to recent_files (keep last 10)
   .file_types[$ext].recent_files |= [$file_path] | 
   .file_types[$ext].recent_files |= unique |
   .file_types[$ext].recent_files = .file_types[$ext].recent_files[-10:]
' "$DATA_FILE" > "${DATA_FILE}.tmp" && mv "${DATA_FILE}.tmp" "$DATA_FILE"

exit 0
#!/bin/bash
# Fast screenshot retrieval script
# Usage: get-screenshots.sh [count]
# Returns the most recent N screenshots from ~/tmp/ai/screenshots/

set -euo pipefail

count=${1:-1}
SCREENSHOT_DIR="$HOME/tmp/ai/screenshots"

# Validate count is a positive integer
if ! [[ "$count" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: count must be a positive integer" >&2
    exit 1
fi

# Create directory if it doesn't exist
if [[ ! -d "$SCREENSHOT_DIR" ]]; then
    mkdir -p "$SCREENSHOT_DIR"
    echo "Info: Created $SCREENSHOT_DIR directory" >&2
fi

# Get the most recent screenshots, sorted by modification time
# Support common image formats
find "$SCREENSHOT_DIR" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" \) -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -n "$count" | cut -d' ' -f2- || {
    echo "No screenshots found in $SCREENSHOT_DIR/" >&2
    exit 1
}
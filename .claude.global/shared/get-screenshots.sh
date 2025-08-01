#!/bin/bash
# Fast screenshot retrieval script
# Usage: get-screenshots.sh [count]
# Returns the most recent N screenshots from ~/.screenshots/

set -euo pipefail

count=${1:-1}

# Validate count is a positive integer
if ! [[ "$count" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: count must be a positive integer" >&2
    exit 1
fi

# Check if screenshots directory exists
if [[ ! -d ~/.screenshots ]]; then
    echo "Error: ~/.screenshots directory does not exist" >&2
    exit 1
fi

# Get the most recent screenshots, sorted by modification time
# Support common image formats
find ~/.screenshots -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" \) -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -n "$count" | cut -d' ' -f2- || {
    echo "No screenshots found in ~/.screenshots/" >&2
    exit 1
}
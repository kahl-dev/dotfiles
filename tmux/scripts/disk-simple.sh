#!/usr/bin/env bash
# Lightweight disk usage monitor for custom tmux status bar
# Returns root partition usage as percentage: "45"

set -euo pipefail

# Cache file for performance
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
readonly CACHE_FILE="$CACHE_DIR/tmux-disk"
readonly CACHE_DURATION=30

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

# Check cache freshness (cross-platform stat)
if [[ -f "$CACHE_FILE" ]]; then
  if [[ "$(uname)" == "Darwin" ]]; then
    file_mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
  else
    file_mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
  fi
  if [[ $(($(date +%s) - file_mtime)) -lt $CACHE_DURATION ]]; then
    cat "$CACHE_FILE"
    exit 0
  fi
fi

# Get main partition usage (works on macOS + Linux)
# macOS APFS: / is a read-only snapshot, actual data is on /System/Volumes/Data
# Linux: / is the real root
if [[ "$(uname)" == "Darwin" ]] && df -P /System/Volumes/Data >/dev/null 2>&1; then
  disk_pct=$(df -P /System/Volumes/Data 2>/dev/null | awk 'NR==2 {gsub(/%/,""); print $5}')
else
  disk_pct=$(df -P / 2>/dev/null | awk 'NR==2 {gsub(/%/,""); print $5}')
fi

# Ensure valid integer
if ! [[ "$disk_pct" =~ ^[0-9]+$ ]]; then
  disk_pct=0
fi

result="${disk_pct}"

# Cache the result
echo "$result" > "$CACHE_FILE"
echo "$result"

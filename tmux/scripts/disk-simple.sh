#!/usr/bin/env bash
# Lightweight disk usage monitor for custom tmux status bar
# Returns root partition usage as percentage: "45"

set -euo pipefail

source "$(dirname "$0")/cache-lib.sh"
CACHE_FILE="$CACHE_DIR/tmux-disk"
check_cache "$CACHE_FILE" 30 && exit 0

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

write_cache "$CACHE_FILE" "$disk_pct"

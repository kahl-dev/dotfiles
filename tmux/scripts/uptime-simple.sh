#!/usr/bin/env bash
# Lightweight uptime monitor for custom tmux status bar
# Returns compact uptime: "3d" or "5h" or "12m"

set -euo pipefail

# Cache file for performance
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
readonly CACHE_FILE="$CACHE_DIR/tmux-uptime"
readonly CACHE_DURATION=60

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

# Get uptime in seconds (cross-platform)
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS: sysctl returns boot time as epoch
  boot_epoch=$(sysctl -n kern.boottime 2>/dev/null | awk '{print $4}' | tr -d ',')
  now_epoch=$(date +%s)
  uptime_seconds=$((now_epoch - boot_epoch))
else
  # Linux: /proc/uptime gives seconds directly
  uptime_seconds=$(awk '{printf "%.0f", $1}' /proc/uptime 2>/dev/null || echo "0")
fi

[[ "$uptime_seconds" =~ ^[0-9]+$ ]] || uptime_seconds=0

# Format compactly
days=$((uptime_seconds / 86400))
hours=$(( (uptime_seconds % 86400) / 3600 ))
minutes=$(( (uptime_seconds % 3600) / 60 ))

if [[ $days -gt 0 ]]; then
  result="${days}d${hours}h"
elif [[ $hours -gt 0 ]]; then
  result="${hours}h${minutes}m"
else
  result="${minutes}m"
fi

# Cache the result
echo "$result" > "$CACHE_FILE"
echo "$result"

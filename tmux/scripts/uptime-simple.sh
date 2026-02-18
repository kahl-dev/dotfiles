#!/usr/bin/env bash
# Lightweight uptime monitor for custom tmux status bar
# Returns compact uptime: "3d5h" or "5h12m" or "12m"

set -euo pipefail

source "$(dirname "$0")/cache-lib.sh"
CACHE_FILE="$CACHE_DIR/tmux-uptime"
check_cache "$CACHE_FILE" 60 && exit 0

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

write_cache "$CACHE_FILE" "$result"

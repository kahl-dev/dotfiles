#!/usr/bin/env bash
# Lightweight CPU monitor for custom tmux status bar
# Returns CPU usage percentage in format: "12%"

set -euo pipefail

# Cache file for performance - use stable path
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
readonly CACHE_FILE="$CACHE_DIR/tmux-cpu"
readonly CACHE_DURATION=3

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

# Get CPU usage - compatible with both macOS and Linux
if command -v top >/dev/null 2>&1; then
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS - extract idle percentage and calculate busy as 100 - idle
    idle_cpu=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $7}' | sed 's/%//' | sed 's/idle//')
    if [[ "$idle_cpu" =~ ^[0-9]+\.?[0-9]*$ ]]; then
      cpu_usage=$(awk "BEGIN {printf \"%.1f\", 100-$idle_cpu}")
    else
      cpu_usage="0"
    fi
  else
    # Linux - extract idle percentage and calculate busy as 100 - idle  
    idle_cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | sed 's/%id,//')
    if [[ "$idle_cpu" =~ ^[0-9]+\.?[0-9]*$ ]]; then
      cpu_usage=$(awk "BEGIN {printf \"%.1f\", 100-$idle_cpu}")
    else
      cpu_usage="0"
    fi
  fi
else
  # Fallback: use iostat if available
  if command -v iostat >/dev/null 2>&1; then
    cpu_usage=$(iostat -c 1 1 | tail -1 | awk '{print 100-$6}')
  else
    cpu_usage="0"
  fi
fi

# Ensure we have a valid number
if ! [[ "$cpu_usage" =~ ^[0-9]+\.?[0-9]*$ ]]; then
  cpu_usage="0"
fi

# Round to integer
cpu_usage=$(printf "%.0f" "$cpu_usage")

# Format output (bare integer — caller adds %)
result="${cpu_usage}"

# Cache the result
echo "$result" > "$CACHE_FILE"
echo "$result"
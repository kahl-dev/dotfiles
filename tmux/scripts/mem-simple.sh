#!/usr/bin/env bash
# Lightweight memory monitor for custom tmux status bar
# Returns memory usage as percentage: "34"

set -euo pipefail

# Cache file for performance - use stable path
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
readonly CACHE_FILE="$CACHE_DIR/tmux-mem"
readonly CACHE_DURATION=5

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

# Check if cache is valid (less than 5 seconds old)
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

# Get memory usage percentage - compatible with both macOS and Linux
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS: try memory_pressure first
  mem_pct=$(memory_pressure 2>/dev/null | grep "System-wide memory free percentage" | awk '{printf "%.0f", 100-$5}' || echo "")

  # Fallback: vm_stat
  if [[ -z "$mem_pct" ]] || ! [[ "$mem_pct" =~ ^[0-9]+$ ]]; then
    total_mem=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
    page_size=$(vm_stat | head -1 | sed 's/.*page size of \([0-9]*\) bytes.*/\1/')
    [[ "$page_size" =~ ^[0-9]+$ ]] || page_size=16384
    vm_stat_output=$(vm_stat)

    pages_wired=$(echo "$vm_stat_output" | grep "Pages wired down" | awk '{print $4}' | sed 's/\.//')
    pages_active=$(echo "$vm_stat_output" | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
    pages_inactive=$(echo "$vm_stat_output" | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')
    pages_compressed=$(echo "$vm_stat_output" | grep "Pages stored in compressor" | awk '{print $5}' | sed 's/\.//' || echo "0")
    # Ensure all page counts are valid integers
    [[ "$pages_wired" =~ ^[0-9]+$ ]] || pages_wired=0
    [[ "$pages_active" =~ ^[0-9]+$ ]] || pages_active=0
    [[ "$pages_inactive" =~ ^[0-9]+$ ]] || pages_inactive=0
    [[ "$pages_compressed" =~ ^[0-9]+$ ]] || pages_compressed=0

    used_pages=$((pages_wired + pages_active + pages_inactive + pages_compressed))
    used_bytes=$((used_pages * page_size))

    if [[ "$total_mem" -gt 0 ]]; then
      mem_pct=$((used_bytes * 100 / total_mem))
    else
      mem_pct=0
    fi
  fi
else
  # Linux
  mem_info=$(cat /proc/meminfo)
  total_kb=$(echo "$mem_info" | grep "MemTotal" | awk '{print $2}')
  available_kb=$(echo "$mem_info" | grep "MemAvailable" | awk '{print $2}')
  if [[ "$total_kb" -gt 0 ]]; then
    mem_pct=$(( (total_kb - available_kb) * 100 / total_kb ))
  else
    mem_pct=0
  fi
fi

# Ensure valid number
if ! [[ "$mem_pct" =~ ^[0-9]+$ ]]; then
  mem_pct=0
fi

result="${mem_pct}"

# Cache the result
echo "$result" > "$CACHE_FILE"
echo "$result"

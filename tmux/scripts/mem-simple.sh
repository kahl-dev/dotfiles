#!/usr/bin/env bash
# Lightweight memory monitor for custom tmux status bar
# Returns memory usage as percentage: "34"

set -euo pipefail

source "$(dirname "$0")/cache-lib.sh"
CACHE_FILE="$CACHE_DIR/tmux-mem"
check_cache "$CACHE_FILE" 5 && exit 0

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

write_cache "$CACHE_FILE" "$mem_pct"

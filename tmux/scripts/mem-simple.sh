#!/usr/bin/env bash
# Lightweight memory monitor for custom tmux status bar
# Returns memory usage in human-readable format: "8.2G"

set -euo pipefail

# Cache file for performance - use stable path
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
readonly CACHE_FILE="$CACHE_DIR/tmux-mem"
readonly CACHE_DURATION=5

# Ensure cache directory exists with restrictive permissions
mkdir -p "$CACHE_DIR"
chmod 700 "$CACHE_DIR"

# Check if cache is valid (less than 5 seconds old)
if [[ -f "$CACHE_FILE" ]] && [[ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0))) -lt $CACHE_DURATION ]]; then
  cat "$CACHE_FILE"
  exit 0
fi

# Get memory usage - compatible with both macOS and Linux
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS
  mem_pressure=$(memory_pressure 2>/dev/null | grep "System-wide memory free percentage" | awk '{print 100-$5}' | sed 's/%//' || echo "0")
  total_mem=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
  
  # If memory_pressure fails, use vm_stat
  if [[ "$mem_pressure" == "0" ]] || ! [[ "$mem_pressure" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    page_size=$(vm_stat | head -1 | sed 's/.*page size of \([0-9]*\) bytes.*/\1/')
    vm_stat_output=$(vm_stat)
    
    pages_wired=$(echo "$vm_stat_output" | grep "Pages wired down" | awk '{print $4}' | sed 's/\.//')
    pages_active=$(echo "$vm_stat_output" | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
    pages_inactive=$(echo "$vm_stat_output" | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')
    pages_compressed=$(echo "$vm_stat_output" | grep "Pages stored in compressor" | awk '{print $5}' | sed 's/\.//' || echo "0")
    
    used_pages=$((pages_wired + pages_active + pages_inactive + pages_compressed))
    used_bytes=$((used_pages * page_size))
  else
    # Use shell arithmetic instead of bc for better compatibility
  if [[ "$mem_pressure" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    # Convert to integer percentage and calculate
    pressure_int=${mem_pressure%.*}
    used_bytes=$((total_mem * pressure_int / 100))
  else
    used_bytes="$total_mem"
  fi
  fi
else
  # Linux
  mem_info=$(cat /proc/meminfo)
  total_mem=$(echo "$mem_info" | grep "MemTotal" | awk '{print $2 * 1024}')
  available_mem=$(echo "$mem_info" | grep "MemAvailable" | awk '{print $2 * 1024}')
  used_bytes=$((total_mem - available_mem))
fi

# Convert to human readable format
format_bytes() {
  local bytes=$1
  local gb=$((bytes / 1024 / 1024 / 1024))
  local mb=$((bytes / 1024 / 1024))
  
  if [[ $gb -gt 0 ]]; then
    local decimal=$((mb % 1024 * 10 / 1024))
    echo "${gb}.${decimal}G"
  elif [[ $mb -gt 0 ]]; then
    echo "${mb}M"
  else
    local kb=$((bytes / 1024))
    echo "${kb}K"
  fi
}

# Ensure we have a valid number
if ! [[ "$used_bytes" =~ ^[0-9]+$ ]] || [[ "$used_bytes" -eq 0 ]]; then
  result="0G"
else
  result=$(format_bytes "$used_bytes")
fi

# Cache the result
echo "$result" > "$CACHE_FILE"
echo "$result"
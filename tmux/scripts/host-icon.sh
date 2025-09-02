#!/usr/bin/env bash
# Host icon detector for tmux status bar
# Returns appropriate icon based on OS and host type

set -euo pipefail

# Cache file for performance - use stable path
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
readonly CACHE_FILE="$CACHE_DIR/tmux-host-icon"
readonly CACHE_DURATION=3600  # 1 hour - host doesn't change often

# Ensure cache directory exists with restrictive permissions
mkdir -p "$CACHE_DIR"
chmod 700 "$CACHE_DIR"

# Check cache
if [[ -f "$CACHE_FILE" ]] && [[ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0))) -lt $CACHE_DURATION ]]; then
  cat "$CACHE_FILE"
  exit 0
fi

# Detect OS and host type
get_host_icon() {
  local os_type=$(uname -s)
  local hostname=$(hostname -s)
  
  case "$os_type" in
    "Darwin")
      # macOS - check for different Mac types
      local model=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Model Name" | cut -d: -f2 | xargs || echo "Mac")
      case "$model" in
        *"MacBook"*) echo "💻" ;;
        *"iMac"*) echo "🖥️" ;;
        *"Mac Studio"*) echo "🎛️" ;;
        *"Mac Pro"*) echo "⚡" ;;
        *"Mac mini"*) echo "📦" ;;
        *) echo "🍎" ;;
      esac
      ;;
    "Linux")
      # Linux - detect distribution
      if [[ -f /etc/os-release ]]; then
        local distro=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
        case "$distro" in
          "ubuntu") echo "🟠" ;;
          "debian") echo "🔴" ;;
          "fedora") echo "🔵" ;;
          "centos"|"rhel") echo "💼" ;;
          "arch") echo "🏗️" ;;
          "alpine") echo "⛰️" ;;
          "raspbian") echo "🍓" ;;
          *) echo "🐧" ;;
        esac
      else
        # Check for Raspberry Pi
        if [[ -f /proc/device-tree/model ]] && grep -q "Raspberry" /proc/device-tree/model 2>/dev/null; then
          echo "🍓"
        else
          echo "🐧"
        fi
      fi
      ;;
    "FreeBSD") echo "😈" ;;
    "OpenBSD") echo "🐡" ;;
    "NetBSD") echo "🚩" ;;
    "SunOS") echo "☀️" ;;
    *) echo "💻" ;;
  esac
}

# Get the icon
icon=$(get_host_icon)

# Cache the result
echo "$icon" > "$CACHE_FILE"
echo "$icon"
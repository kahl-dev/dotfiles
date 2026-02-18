#!/usr/bin/env bash
# Hostname display mapper for tmux status bar
# Returns custom display names for different machines

set -euo pipefail

source "$(dirname "$0")/cache-lib.sh"
CACHE_FILE="$CACHE_DIR/tmux-hostname"
check_cache "$CACHE_FILE" 300 && exit 0

# Get current hostname
current_hostname=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "unknown")

# Hostname mapping - customize as needed
get_display_name() {
  case "$current_hostname" in
    # Default machine - show nothing (empty)
    "Patricks-MacBook-14-Pro")
      echo ""
      ;;

    # Add more mappings here as needed:
    # "ubuntu-server")
    #   echo "ubuntu"
    #   ;;
    # "raspberry-pi")
    #   echo "rpi"
    #   ;;
    # "work-laptop")
    #   echo "work"
    #   ;;

    # Default: show full hostname for unknown machines
    *)
      echo "$current_hostname"
      ;;
  esac
}

display_name=$(get_display_name)
write_cache "$CACHE_FILE" "$display_name"

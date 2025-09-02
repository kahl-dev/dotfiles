#!/usr/bin/env bash
# Hostname display mapper for tmux status bar
# Returns custom display names for different machines

set -euo pipefail

# Cache file for performance - use stable path
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
readonly CACHE_FILE="$CACHE_DIR/tmux-hostname"
readonly CACHE_DURATION=300  # 5 minutes - hostname doesn't change often

# Ensure cache directory exists with restrictive permissions
mkdir -p "$CACHE_DIR"
chmod 700 "$CACHE_DIR"

# Check cache
if [[ -f "$CACHE_FILE" ]] && [[ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0))) -lt $CACHE_DURATION ]]; then
  cat "$CACHE_FILE"
  exit 0
fi

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

# Get the display name
display_name=$(get_display_name)

# Cache the result
echo "$display_name" > "$CACHE_FILE"
echo "$display_name"
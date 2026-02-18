#!/usr/bin/env bash
# Host icon detector for tmux status bar
# Returns appropriate Nerd Font icon based on OS

set -euo pipefail

# Cache file for performance - use stable path
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
readonly CACHE_FILE="$CACHE_DIR/tmux-host-icon"
readonly CACHE_DURATION=3600  # 1 hour - host doesn't change often

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

# Check cache (cross-platform stat)
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

# Detect OS and return Nerd Font icon
get_host_icon() {
  local os_type
  os_type=$(uname -s)

  case "$os_type" in
    "Darwin")
      # nf-fa-apple
      echo $'\uf179'
      ;;
    "Linux")
      if [[ -f /etc/os-release ]]; then
        local distro
        distro=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
        case "$distro" in
          "ubuntu")   echo $'\uf31b' ;;  # nf-linux-ubuntu
          "debian")   echo $'\uf306' ;;  # nf-linux-debian
          "fedora")   echo $'\uf30a' ;;  # nf-linux-fedora
          "centos"|"rhel") echo $'\uf304' ;;  # nf-linux-centos
          "arch")     echo $'\uf303' ;;  # nf-linux-archlinux
          "alpine")   echo $'\uf300' ;;  # nf-linux-alpine
          "raspbian") echo $'\uf315' ;;  # nf-linux-raspberry_pi
          *)          echo $'\uf17c' ;;  # nf-fa-linux
        esac
      elif [[ -f /proc/device-tree/model ]] && grep -q "Raspberry" /proc/device-tree/model 2>/dev/null; then
        echo $'\uf315'  # nf-linux-raspberry_pi
      else
        echo $'\uf17c'  # nf-fa-linux
      fi
      ;;
    "FreeBSD") echo $'\uf30c' ;;  # nf-linux-freebsd
    "OpenBSD") echo $'\uf17c' ;;  # nf-fa-linux (no native OpenBSD icon)
    "NetBSD")  echo $'\uf17c' ;;  # nf-fa-linux (no native NetBSD icon)
    "SunOS")   echo $'\uf185' ;;  # nf-fa-sun_o
    *)         echo $'\uf17c' ;;  # nf-fa-linux fallback
  esac
}

# Get the icon
icon=$(get_host_icon)

# Cache the result
echo "$icon" > "$CACHE_FILE"
echo "$icon"

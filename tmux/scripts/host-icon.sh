#!/usr/bin/env bash
# Host icon detector for tmux status bar
# Returns appropriate Nerd Font icon based on OS

set -euo pipefail

source "$(dirname "$0")/cache-lib.sh"
CACHE_FILE="$CACHE_DIR/tmux-host-icon"
check_cache "$CACHE_FILE" 3600 && exit 0

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

icon=$(get_host_icon)
write_cache "$CACHE_FILE" "$icon"

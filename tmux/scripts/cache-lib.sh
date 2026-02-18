#!/usr/bin/env bash
# Shared cache utilities for tmux status scripts
# Source this file: source "$(dirname "$0")/cache-lib.sh"

[[ "${BASH_SOURCE[0]}" == "$0" ]] && { echo "This file must be sourced, not executed." >&2; exit 1; }

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
mkdir -p "$CACHE_DIR"

# check_cache CACHE_FILE CACHE_DURATION
# Returns 0 (hit) and prints cached value, or 1 (miss)
check_cache() {
  local cache_file=$1 cache_duration=$2
  [[ -f "$cache_file" ]] || return 1
  local file_mtime
  if [[ "$(uname)" == "Darwin" ]]; then
    file_mtime=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
  else
    file_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
  fi
  if [[ $(( $(date +%s) - file_mtime )) -lt $cache_duration ]]; then
    cat "$cache_file"
    return 0
  fi
  return 1
}

# write_cache CACHE_FILE VALUE
# Uses atomic rename to prevent partial reads on concurrent access
write_cache() {
  local tmp_file
  tmp_file=$(mktemp "${1}.XXXXXX")
  echo "$2" > "$tmp_file"
  mv "$tmp_file" "$1"
  echo "$2"
}

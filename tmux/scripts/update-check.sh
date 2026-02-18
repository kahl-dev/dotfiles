#!/usr/bin/env bash
set -euo pipefail

# Check toggle (mirrors claude-usage.sh pattern)
show_check="on"
if command -v tmux >/dev/null 2>&1; then
  show_check=$(tmux show -gqv @show-update-check 2>/dev/null)
  show_check="${show_check:-on}"
fi
[[ "$show_check" != "on" ]] && exit 0

source "$(dirname "$0")/cache-lib.sh"

CACHE_FILE="$CACHE_DIR/tmux-update-check"
check_cache "$CACHE_FILE" 60 && exit 0

stale=0
now=$(date +%s)

# CRITICAL: Must use if/then, NOT (( )) && ...
# With set -e, (( false_expr )) && cmd returns 1 and kills the script
check_age() {
  local file="$1" threshold="$2"
  local mtime
  mtime=$(file_mtime "$file")
  if (( (now - mtime) > threshold )); then
    stale=$((stale + 1))
  fi
}

# mtime=0 when file missing -> age = $now seconds -> always stale
check_age "${CACHE_DIR}/dot-last-brew-update" $((7 * 86400))
check_age "${CACHE_DIR}/dot-last-mise-update" $((7 * 86400))
check_age "${CACHE_DIR}/dot-last-tpm-update"  $((30 * 86400))
check_age "${CACHE_DIR}/dot-last-repos-sync"  $((3 * 86400))

if (( stale > 0 )); then
  write_cache "$CACHE_FILE" "$stale"
else
  write_cache "$CACHE_FILE" ""
fi

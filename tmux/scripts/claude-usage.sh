#!/usr/bin/env bash
# Claude Code usage quota for tmux status bar
# Output: 5h_pct|7d_pct|daily_budget|days_left|workdays_left|pace
# Example: 55|43|12|3|2|under
# Silent exit on any error → segment vanishes from status bar

set -euo pipefail

# Check toggle (default: on when not in tmux or unset)
show_usage="on"
if command -v tmux >/dev/null 2>&1; then
  show_usage=$(tmux show -gqv @show-claude-usage 2>/dev/null)
  show_usage="${show_usage:-on}"
fi
[[ "$show_usage" != "on" ]] && exit 0

source "$(dirname "$0")/cache-lib.sh"
CACHE_FILE="$CACHE_DIR/tmux-claude-usage"
check_cache "$CACHE_FILE" 60 && exit 0

# Require jq
command -v jq >/dev/null 2>&1 || exit 0

# Get OAuth access token
get_access_token() {
  if [[ "$(uname)" == "Darwin" ]]; then
    local credentials
    credentials=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null) || return 1
    echo "$credentials" | jq -r '.claudeAiOauth.accessToken // .accessToken // empty' 2>/dev/null
  else
    local credentials_file="$HOME/.claude/.credentials.json"
    [[ -f "$credentials_file" ]] || return 1
    jq -r '.claudeAiOauth.accessToken // .accessToken // empty' "$credentials_file" 2>/dev/null
  fi
}

access_token=$(get_access_token) || exit 0
[[ -z "$access_token" ]] && exit 0

# Fetch usage from OAuth endpoint
response=$(curl -s --max-time 5 \
  -H "Authorization: Bearer $access_token" \
  -H "anthropic-beta: oauth-2025-04-20" \
  "https://api.anthropic.com/api/oauth/usage" 2>/dev/null) || exit 0

# Parse utilization and reset timestamps
five_hour=$(echo "$response" | jq -r '.five_hour.utilization // empty' 2>/dev/null) || exit 0
seven_day=$(echo "$response" | jq -r '.seven_day.utilization // empty' 2>/dev/null) || exit 0
seven_day_resets_at=$(echo "$response" | jq -r '.seven_day.resets_at // empty' 2>/dev/null) || exit 0

[[ -z "$five_hour" || -z "$seven_day" || -z "$seven_day_resets_at" ]] && exit 0

# Round to integer percentages (API returns 0-100 floats)
five_hour_pct=$(awk "BEGIN {printf \"%.0f\", $five_hour}" 2>/dev/null) || exit 0
seven_day_pct=$(awk "BEGIN {printf \"%.0f\", $seven_day}" 2>/dev/null) || exit 0

# Calculate days until 7d reset
now_epoch=$(date +%s)

# Clean ISO 8601 timestamp for macOS date parsing
reset_clean="${seven_day_resets_at%%.*}"  # remove fractional seconds
reset_clean="${reset_clean%Z}"            # remove trailing Z
reset_clean="${reset_clean%+00:00}"       # remove UTC offset

if [[ "$(uname)" == "Darwin" ]]; then
  reset_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$reset_clean" +%s 2>/dev/null) || exit 0
else
  # Linux: date -d handles ISO 8601 natively
  reset_epoch=$(date -d "$seven_day_resets_at" +%s 2>/dev/null) || exit 0
fi

seconds_left=$((reset_epoch - now_epoch))

# Window has reset or is resetting — cache empty to avoid repeated API calls
if [[ $seconds_left -le 0 ]]; then
  write_cache "$CACHE_FILE" "" > /dev/null
  exit 0
fi

# Days left (ceiling: partial day counts as 1)
days_left=$(( (seconds_left + 86399) / 86400 ))

# Count workdays (Mon-Fri) with pure arithmetic (zero additional forks)
# Get current day of week once (1=Mon ... 7=Sun)
if [[ "$(uname)" == "Darwin" ]]; then
  start_dow=$(date -j -f "%s" "$now_epoch" +%u 2>/dev/null) || start_dow=1
else
  start_dow=$(date -d "@$now_epoch" +%u 2>/dev/null) || start_dow=1
fi

workdays_left=0
for (( i=0; i<days_left; i++ )); do
  dow=$(( (start_dow + i - 1) % 7 + 1 ))
  [[ $dow -le 5 ]] && workdays_left=$((workdays_left + 1))
done

# Calculate daily budget: remaining% / days_left
[[ $days_left -gt 0 ]] || exit 0
remaining_pct=$((100 - seven_day_pct))
[[ $remaining_pct -lt 0 ]] && remaining_pct=0
daily_budget=$((remaining_pct / days_left))

# Pace: compare daily budget to ideal (100/7 ≈ 14%)
# ▲ = on track or ahead, ▼ = burning too fast
readonly IDEAL_PER_DAY=14
if [[ $daily_budget -ge $IDEAL_PER_DAY ]]; then
  pace="under"
else
  pace="over"
fi

result="${five_hour_pct}|${seven_day_pct}|${daily_budget}|${days_left}|${workdays_left}|${pace}"

write_cache "$CACHE_FILE" "$result"

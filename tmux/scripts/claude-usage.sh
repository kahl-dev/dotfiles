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

# Cache configuration
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
readonly CACHE_FILE="$CACHE_DIR/tmux-claude-usage"
readonly CACHE_DURATION=60

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

# Check cache freshness (cross-platform stat)
if [[ -f "$CACHE_FILE" ]]; then
  if [[ "$(uname)" == "Darwin" ]]; then
    file_mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
  else
    file_mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
  fi
  cache_age=$(( $(date +%s) - file_mtime ))
  if [[ $cache_age -lt $CACHE_DURATION ]]; then
    cat "$CACHE_FILE"
    exit 0
  fi
fi

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

# Window has reset or is resetting — skip budget calculation
[[ $seconds_left -le 0 ]] && exit 0

# Days left (ceiling: partial day counts as 1)
days_left=$(( (seconds_left + 86399) / 86400 ))

# Count workdays (Mon-Fri) in remaining days
workdays_left=0
for (( day_offset=0; day_offset<days_left; day_offset++ )); do
  future_epoch=$((now_epoch + day_offset * 86400))
  if [[ "$(uname)" == "Darwin" ]]; then
    day_of_week=$(date -j -f "%s" "$future_epoch" +%u 2>/dev/null) || continue
  else
    day_of_week=$(date -d "@$future_epoch" +%u 2>/dev/null) || continue
  fi
  # %u: 1=Mon ... 5=Fri, 6=Sat, 7=Sun
  [[ $day_of_week -le 5 ]] && workdays_left=$((workdays_left + 1))
done

# Calculate daily budget: remaining% / days_left
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

# Cache and output
echo "$result" > "$CACHE_FILE"
echo "$result"

#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/cache-lib.sh"
source "${DOTFILES:-$HOME/.dotfiles}/zsh/config/update-registry.sh"
UPDATE_CACHE="$CACHE_DIR/tmux-update-check"

# ============================================================================
# Catppuccin Mocha palette (ANSI 24-bit true color)
# ============================================================================

COLOR_BLUE=$'\033[38;2;137;180;250m'
COLOR_GREEN=$'\033[38;2;166;227;161m'
COLOR_RED=$'\033[38;2;243;139;168m'
COLOR_PEACH=$'\033[38;2;250;179;135m'
COLOR_DIM=$'\033[38;2;108;112;134m'
COLOR_TEXT=$'\033[38;2;205;214;244m'
COLOR_BOLD=$'\033[1m'
COLOR_RESET=$'\033[0m'

# ============================================================================
# Helpers
# ============================================================================

human_age() {
  local seconds="$1"
  if (( seconds < 3600 )); then
    echo "$((seconds / 60))m ago"
  elif (( seconds < 86400 )); then
    echo "$((seconds / 3600))h ago"
  else
    echo "$((seconds / 86400))d ago"
  fi
}

freshness_color() {
  local age="$1" threshold="$2"
  if (( age > threshold )); then
    printf '%s' "$COLOR_RED"
  elif (( age > threshold * 3 / 4 )); then
    printf '%s' "$COLOR_PEACH"
  else
    printf '%s' "$COLOR_GREEN"
  fi
}

separator() {
  echo "  ${COLOR_DIM}────────────────────────────────────${COLOR_RESET}"
}

done_message() {
  echo ""
  echo "  ${COLOR_GREEN} Done${COLOR_RESET}  ${COLOR_DIM}Press any key to close${COLOR_RESET}"
  read -rsn1
}

# ============================================================================
# Status display
# ============================================================================

now=$(date +%s)
tool_count=${#DOT_UPDATE_TOOLS[@]}

# Header
echo ""
echo "  ${COLOR_BLUE}${COLOR_BOLD}󰚰 Update Status${COLOR_RESET}"
echo ""
separator
echo ""

# Status rows — driven by shared registry
for i in "${!DOT_UPDATE_TOOLS[@]}"; do
  _dot_parse_tool "${DOT_UPDATE_TOOLS[$i]}"
  threshold_seconds=$(( _threshold * 86400 ))
  mtime=$(file_mtime "$CACHE_DIR/dot-last-${_cache_key}")
  age=$((now - mtime))
  age_str=$(human_age "$age")
  color=$(freshness_color "$age" "$threshold_seconds")

  idx=$((i + 1))

  if (( age > threshold_seconds )); then
    status="${COLOR_RED}${COLOR_BOLD}OVERDUE${COLOR_RESET}"
    printf "  ${COLOR_DIM}%d${COLOR_RESET}  %b  ${COLOR_TEXT}%-12s${COLOR_RESET} %b%-10s${COLOR_RESET}  %b\n" \
      "$idx" "${color}${_icon}${COLOR_RESET}" "$_label" "$color" "$age_str" "$status"
  else
    remaining=$(( (threshold_seconds - age) / 86400 ))
    printf "  ${COLOR_DIM}%d${COLOR_RESET}  %b  ${COLOR_TEXT}%-12s${COLOR_RESET} %b%-10s${COLOR_RESET}  ${COLOR_DIM}next in %dd${COLOR_RESET}\n" \
      "$idx" "${color}${_icon}${COLOR_RESET}" "$_label" "$color" "$age_str" "$remaining"
  fi
done

# Menu
echo ""
separator
echo ""
echo "  ${COLOR_DIM}1-${tool_count}${COLOR_TEXT} individual ${COLOR_DIM}│${COLOR_RESET} ${COLOR_BLUE}a${COLOR_TEXT} all tools ${COLOR_DIM}│${COLOR_RESET} ${COLOR_DIM}q${COLOR_TEXT} close${COLOR_RESET}"
echo ""

read -rsn1 choice

# ============================================================================
# Actions — delegate to dot update (single source of truth)
# ============================================================================

set +e  # updates may return non-zero (e.g. brew upgrade partial failure)

if [[ "$choice" == "a" ]]; then
  echo ""
  echo "  ${COLOR_BLUE}${COLOR_BOLD}󰚰 Updating All Tools...${COLOR_RESET}"
  echo ""
  for entry in "${DOT_UPDATE_TOOLS[@]}"; do
    _dot_parse_tool "$entry"
    echo "  ${COLOR_TEXT}${COLOR_BOLD}${_icon} ${_label}${COLOR_RESET}"
    zsh -ic "dot update --yes $_name" 2>&1 | sed 's/^Update complete:.*//' | sed '/^$/d' | sed 's/^/  /'
    echo ""
  done
  done_message
elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= tool_count )); then
  idx=$((choice - 1))
  _dot_parse_tool "${DOT_UPDATE_TOOLS[$idx]}"
  echo ""
  echo "  ${COLOR_BLUE}${COLOR_BOLD}${_icon} Updating ${_label}...${COLOR_RESET}"
  echo ""
  zsh -ic "dot update --yes $_name" 2>&1 | sed 's/^Update complete:.*//' | sed '/^$/d' | sed 's/^/  /'
  done_message
fi

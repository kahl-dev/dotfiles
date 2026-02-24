#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/cache-lib.sh"
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
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
# Tool definitions
# ============================================================================

# Nerd Font icons per tool
TOOL_NAMES=("brew" "mise" "tpm" "repos")
TOOL_ICONS=("󰜁" "" "󰐱" "󰊢")
TOOL_LABELS=("Homebrew" "Mise" "TPM" "Repos")
TOOL_THRESHOLDS=(7 7 30 3)
TOOL_CACHES=("dot-last-brew-update" "dot-last-mise-update" "dot-last-tpm-update" "dot-last-repos-sync")

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

_touch() {
  touch "$CACHE_DIR/dot-last-${1}"
  rm -f "$UPDATE_CACHE"
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

section_header() {
  local icon="$1" label="$2"
  echo ""
  echo "  ${COLOR_BLUE}${COLOR_BOLD}${icon} ${label}${COLOR_RESET}"
  echo ""
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

# Header
echo ""
echo "  ${COLOR_BLUE}${COLOR_BOLD}󰚰 Update Status${COLOR_RESET}"
echo ""
separator
echo ""

# Status rows
for i in "${!TOOL_NAMES[@]}"; do
  threshold_seconds=$(( TOOL_THRESHOLDS[i] * 86400 ))
  mtime=$(file_mtime "$CACHE_DIR/${TOOL_CACHES[$i]}")
  age=$((now - mtime))
  age_str=$(human_age "$age")
  color=$(freshness_color "$age" "$threshold_seconds")

  idx=$((i + 1))

  if (( age > threshold_seconds )); then
    status="${COLOR_RED}${COLOR_BOLD}OVERDUE${COLOR_RESET}"
    printf "  ${COLOR_DIM}%d${COLOR_RESET}  %b  ${COLOR_TEXT}%-12s${COLOR_RESET} %b%-10s${COLOR_RESET}  %b\n" \
      "$idx" "${color}${TOOL_ICONS[$i]}${COLOR_RESET}" "${TOOL_LABELS[$i]}" "$color" "$age_str" "$status"
  else
    remaining=$(( (threshold_seconds - age) / 86400 ))
    printf "  ${COLOR_DIM}%d${COLOR_RESET}  %b  ${COLOR_TEXT}%-12s${COLOR_RESET} %b%-10s${COLOR_RESET}  ${COLOR_DIM}next in %dd${COLOR_RESET}\n" \
      "$idx" "${color}${TOOL_ICONS[$i]}${COLOR_RESET}" "${TOOL_LABELS[$i]}" "$color" "$age_str" "$remaining"
  fi
done

# Menu
echo ""
separator
echo ""
echo "  ${COLOR_DIM}1-4${COLOR_TEXT} individual ${COLOR_DIM}│${COLOR_RESET} ${COLOR_BLUE}a${COLOR_TEXT} all tools ${COLOR_DIM}│${COLOR_RESET} ${COLOR_BLUE}r${COLOR_TEXT} repos ${COLOR_DIM}│${COLOR_RESET} ${COLOR_DIM}q${COLOR_TEXT} close${COLOR_RESET}"
echo ""

read -rsn1 choice

# ============================================================================
# Actions
# ============================================================================

case "$choice" in
  1)
    section_header "󰜁" "Updating Homebrew..."
    brew update && brew upgrade && { brew cleanup -s; _touch "brew-update"; }
    done_message
    ;;
  2)
    section_header "" "Upgrading Mise..."
    mise upgrade && _touch "mise-update"
    done_message
    ;;
  3)
    section_header "󰐱" "Updating TPM Plugins..."
    "$DOTFILES/tmux/plugins/tpm/bin/update_plugins" all && _touch "tpm-update"
    done_message
    ;;
  4|r)
    section_header "󰊢" "Syncing Repos..."
    SYNC_REPOS=("$HOME/.dotfiles" "$HOME/repos/claude-config")
    if [[ -n "${TMUX_EXTRA_SYNC_REPOS:-}" ]]; then
      IFS=':' read -ra extra <<< "$TMUX_EXTRA_SYNC_REPOS"
      SYNC_REPOS+=("${extra[@]}")
    fi
    for repo_dir in "${SYNC_REPOS[@]}"; do
      [[ -d "$repo_dir/.git" ]] || continue
      name=$(basename "$repo_dir")
      echo "  ${COLOR_DIM}${name}${COLOR_RESET}"
      timeout 15 git -C "$repo_dir" fetch --quiet 2>/dev/null || {
        echo "    ${COLOR_PEACH} fetch timed out${COLOR_RESET}"
        continue
      }
      dirty=$(git -C "$repo_dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      if (( dirty > 0 )); then
        echo "    ${COLOR_PEACH} ${dirty} uncommitted, skipping pull${COLOR_RESET}"
      else
        git -C "$repo_dir" pull --rebase --autostash 2>&1 | sed "s/^/    /"
      fi
      ahead=$(git -C "$repo_dir" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
      if [[ "$ahead" =~ ^[0-9]+$ ]] && (( ahead > 0 )); then
        echo "    ${COLOR_BLUE} pushing ${ahead} commit(s)${COLOR_RESET}"
        git -C "$repo_dir" push 2>&1 | sed "s/^/    /"
      fi
    done
    _touch "repos-sync"
    done_message
    ;;
  a)
    section_header "󰚰" "Updating All Tools..."
    echo "  ${COLOR_TEXT}${COLOR_BOLD}󰜁 Homebrew${COLOR_RESET}"
    brew update && brew upgrade && { brew cleanup -s; _touch "brew-update"; }
    echo ""
    echo "  ${COLOR_TEXT}${COLOR_BOLD} Mise${COLOR_RESET}"
    mise upgrade && _touch "mise-update"
    echo ""
    echo "  ${COLOR_TEXT}${COLOR_BOLD}󰐱 TPM${COLOR_RESET}"
    "$DOTFILES/tmux/plugins/tpm/bin/update_plugins" all && _touch "tpm-update"
    done_message
    ;;
  q|*) ;;
esac

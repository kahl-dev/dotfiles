#!/usr/bin/env zsh
# 📊 dot status — dotfiles health dashboard

_dot_status() {
  echo ""
  echo "${_dot_bold}dot status${_dot_reset} — dotfiles health"
  echo ""

  # Dotfiles git status
  local git_branch git_dirty
  git_branch=$(git -C "$DOTFILES" branch --show-current 2>/dev/null)
  git_dirty=$(git -C "$DOTFILES" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  local git_status="$git_branch"
  if (( git_dirty > 0 )); then
    git_status="$git_branch ⚠️  ($git_dirty uncommitted)"
  else
    git_status="$git_branch ✓"
  fi
  printf "  📦 Dotfiles     %s\n" "$git_status"

  # Homebrew
  if command_exists brew; then
    local formula_count cask_count
    formula_count=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')
    cask_count=$(brew list --cask 2>/dev/null | wc -l | tr -d ' ')
    printf "  🍺 Homebrew     %s formulae, %s casks\n" "$formula_count" "$cask_count"
  fi

  # Mise
  if command_exists mise; then
    local tool_count
    tool_count=$(mise list 2>/dev/null | wc -l | tr -d ' ')
    printf "  🔧 mise         %s tools installed\n" "$tool_count"
  fi

  # Zinit plugins
  local zinit_plugins="${ZINIT_ROOT:-$HOME/.local/share/zinit}/plugins"
  if [[ -d "$zinit_plugins" ]]; then
    local plugin_count=0
    for dir in "$zinit_plugins"/*(N/); do
      [[ "${dir:t}" == "_local---zinit" ]] && continue
      (( plugin_count++ ))
    done
    printf "  🔌 zinit        %s plugins loaded\n" "$plugin_count"
  fi

  # Disk space
  local free_gb
  free_gb=$(df -g "$HOME" 2>/dev/null | awk 'NR==2 {print $4}')
  if [[ -n "$free_gb" ]]; then
    printf "  📊 Disk         %sGB free\n" "$free_gb"
  fi

  # Reclaimable estimate (fast check of known cache dirs)
  local reclaimable=0
  for dir in \
    "$HOME/Library/Caches/Homebrew" \
    "$HOME/Library/Caches/uv" \
    "$HOME/.cache/uv" \
    "$HOME/.cache/puppeteer" \
    "$HOME/.cache/pre-commit"; do
    if [[ -d "$dir" ]]; then
      local dir_size
      dir_size=$(du -sk "$dir" 2>/dev/null | awk '{print $1}')
      (( reclaimable += dir_size ))
    fi
  done
  if (( reclaimable > 1024 )); then
    local reclaimable_display
    if (( reclaimable >= 1048576 )); then
      reclaimable_display="~$(( reclaimable / 1048576 ))GB"
    else
      reclaimable_display="~$(( reclaimable / 1024 ))MB"
    fi
    printf "  🧹 Cleanable    %s  (dot clean --dry-run)\n" "$reclaimable_display"
  fi

  echo ""
}

#!/usr/bin/env zsh
# 🧹 dot clean — unified cache and temp cleanup

_dot_clean() {
  local dry_run=false
  local auto_yes=false
  local -a requested_categories=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run|-n) dry_run=true; shift ;;
      --yes|-y) auto_yes=true; shift ;;
      all) requested_categories=($(_dot_clean_all_categories)); shift ;;
      *) requested_categories+=("$1"); shift ;;
    esac
  done

  # Interactive mode: show each category
  if (( ${#requested_categories} == 0 )); then
    requested_categories=($(_dot_clean_all_categories))
    auto_yes=false
  fi

  local total_freed=0

  for category in "${requested_categories[@]}"; do
    local func="_dot_clean_${category}"
    if (( $+functions[$func] )); then
      $func
    else
      echo "dot clean: unknown category '$category'" >&2
      echo "Available: $(_dot_clean_all_categories | tr '\n' ' ')" >&2
      return 1
    fi
  done

  echo ""
  if $dry_run; then
    echo "Dry run complete. No files were deleted."
  else
    echo "Cleanup complete."
  fi
}

_dot_clean_all_categories() {
  echo brew
  echo uv
  echo docker
  echo nvim
  echo node
  echo logs
  echo caches
  echo claude
  echo claude-plugins
  echo home
  echo yarn
  echo playwright
  echo composer
  echo pip
  echo tmp
}

# ── Helper: size display ─────────────────────────────────────────────────────
_dot_clean_format_size() {
  local size_kb="$1"
  if (( size_kb >= 1048576 )); then
    echo "$(( size_kb / 1048576 )).$(( (size_kb % 1048576) * 10 / 1048576 ))GB"
  elif (( size_kb >= 1024 )); then
    echo "$(( size_kb / 1024 ))MB"
  else
    echo "${size_kb}KB"
  fi
}

_dot_clean_dir_size() {
  du -sk "$1" 2>/dev/null | awk '{print $1}'
}

_dot_clean_should_run() {
  local category="$1" size_display="$2"
  echo ""
  echo "  🧹 $category ($size_display)"
  if $dry_run; then
    echo "     [dry-run] Would clean"
    return 1
  fi
  # Docker is always prompted, never auto-yes
  if [[ "$category" == "docker" ]] && $auto_yes; then
    echo "     [skipped] Docker excluded from --yes (use 'dot clean docker' explicitly)"
    return 1
  fi
  if $auto_yes; then
    return 0
  fi
  _dot_ask "     Clean $category?"
}

# ── Categories ───────────────────────────────────────────────────────────────

_dot_clean_brew() {
  if ! command_exists brew; then
    echo "  ✓ brew: not installed"
    return
  fi
  # macOS: ~/Library/Caches/Homebrew, Linux: ~/.cache/Homebrew
  local cache_dir="$HOME/Library/Caches/Homebrew"
  [[ -d "$cache_dir" ]] || cache_dir="$HOME/.cache/Homebrew"
  if [[ ! -d "$cache_dir" ]]; then
    echo "  ✓ brew: no cache"
    return
  fi
  local size=$(_dot_clean_dir_size "$cache_dir")
  local display=$(_dot_clean_format_size "$size")
  if _dot_clean_should_run "brew" "$display"; then
    brew cleanup -s --prune=all
    echo "     Cleaned"
  fi
}

_dot_clean_uv() {
  if ! command_exists uv; then
    echo "  ✓ uv: not installed"
    return
  fi
  local cache_dir="$HOME/Library/Caches/uv"
  [[ -d "$cache_dir" ]] || cache_dir="$HOME/.cache/uv"
  if [[ ! -d "$cache_dir" ]]; then
    echo "  ✓ uv: no cache"
    return
  fi
  local size=$(_dot_clean_dir_size "$cache_dir")
  local display=$(_dot_clean_format_size "$size")
  if _dot_clean_should_run "uv" "$display"; then
    uv cache clean
    echo "     Cleaned"
  fi
}

_dot_clean_docker() {
  if ! command_exists docker; then
    echo "  ✓ docker: not installed"
    return
  fi
  # Check if docker daemon is running
  if ! docker info &>/dev/null; then
    echo "  ✓ docker: daemon not running"
    return
  fi
  local size
  size=$(docker system df --format '{{.Reclaimable}}' 2>/dev/null | head -1)
  if _dot_clean_should_run "docker" "${size:-unknown}"; then
    docker system prune -a
    echo "     Cleaned"
  fi
}

_dot_clean_nvim() {
  local -a dirs_to_clean=()
  local total_size=0

  # Swap files
  local swap_dir="$HOME/.local/state/nvim/swap"
  [[ -d "$swap_dir" ]] && dirs_to_clean+=("$swap_dir")

  # Shada (shared data)
  local shada_dir="$HOME/.local/state/nvim"
  for f in "$shada_dir"/shada/*(N) "$shada_dir"/*.shada(N); do
    [[ -f "$f" ]] && dirs_to_clean+=("shada")
    break
  done

  # Old log files
  local log_file="$HOME/.local/state/nvim/log"
  [[ -f "$log_file" ]] && dirs_to_clean+=("log")

  if (( ${#dirs_to_clean} == 0 )); then
    echo "  ✓ nvim: clean"
    return
  fi

  # Calculate total size
  for item in "$HOME/.local/state/nvim/swap" "$HOME/.local/state/nvim/shada" "$HOME/.local/state/nvim/log"; do
    [[ -e "$item" ]] && (( total_size += $(_dot_clean_dir_size "$item") ))
  done
  local display=$(_dot_clean_format_size "$total_size")

  if _dot_clean_should_run "nvim" "$display"; then
    [[ -d "$swap_dir" ]] && rm -rf "$swap_dir"/*.sw[op] 2>/dev/null
    rm -f "$HOME/.local/state/nvim"/*.shada.tmp* 2>/dev/null
    # Truncate log if >10MB
    if [[ -f "$log_file" ]]; then
      local log_size
      log_size=$(wc -c < "$log_file" 2>/dev/null | tr -d ' ')
      (( log_size > 10485760 )) && : > "$log_file"
    fi
    echo "     Cleaned"
  fi
}

_dot_clean_node() {
  if ! command_exists pnpm; then
    echo "  ✓ node: pnpm not installed"
    return
  fi
  local store_path
  store_path=$(pnpm store path 2>/dev/null)
  if [[ -z "$store_path" || ! -d "$store_path" ]]; then
    echo "  ✓ node: no pnpm store"
    return
  fi
  local size=$(_dot_clean_dir_size "$store_path")
  local display=$(_dot_clean_format_size "$size")
  if _dot_clean_should_run "node (pnpm store)" "$display"; then
    pnpm store prune
    echo "     Cleaned"
  fi
}

_dot_clean_logs() {
  local total_size=0
  local -a log_dirs=()

  # Remote Bridge rotated logs
  local rb_logs="$DOTFILES/remote-bridge/logs"
  if [[ -d "$rb_logs" ]]; then
    log_dirs+=("$rb_logs")
    (( total_size += $(_dot_clean_dir_size "$rb_logs") ))
  fi

  # Claude debug logs older than 30 days
  local claude_logs="$HOME/.claude/logs/debug"
  if [[ -d "$claude_logs" ]]; then
    log_dirs+=("$claude_logs")
    (( total_size += $(_dot_clean_dir_size "$claude_logs") ))
  fi

  if (( ${#log_dirs} == 0 )); then
    echo "  ✓ logs: none"
    return
  fi

  local display=$(_dot_clean_format_size "$total_size")
  if _dot_clean_should_run "logs" "$display"; then
    # Clean Remote Bridge rotated logs (keep current)
    if [[ -d "$rb_logs" ]]; then
      find "$rb_logs" -name "*.log.*" -mtime +7 -delete 2>/dev/null
    fi
    # Clean Claude debug logs older than 30 days
    if [[ -d "$claude_logs" ]]; then
      find "$claude_logs" -type f -mtime +30 -delete 2>/dev/null
    fi
    echo "     Cleaned"
  fi
}

_dot_clean_caches() {
  local total_size=0
  local -a cache_dirs=()

  # Puppeteer cache
  local puppeteer="$HOME/.cache/puppeteer"
  if [[ -d "$puppeteer" ]]; then
    cache_dirs+=("$puppeteer")
    (( total_size += $(_dot_clean_dir_size "$puppeteer") ))
  fi

  # Chrome DevTools MCP
  local chrome_mcp="$HOME/.cache/chrome-devtools-mcp"
  if [[ -d "$chrome_mcp" ]]; then
    cache_dirs+=("$chrome_mcp")
    (( total_size += $(_dot_clean_dir_size "$chrome_mcp") ))
  fi

  # pre-commit
  local precommit="$HOME/.cache/pre-commit"
  if [[ -d "$precommit" ]]; then
    cache_dirs+=("$precommit")
    (( total_size += $(_dot_clean_dir_size "$precommit") ))
  fi

  if (( ${#cache_dirs} == 0 )); then
    echo "  ✓ caches: none"
    return
  fi

  local display=$(_dot_clean_format_size "$total_size")
  if _dot_clean_should_run "caches" "$display"; then
    for dir in "${cache_dirs[@]}"; do
      rm -rf "$dir"
      echo "     removed ${dir/#$HOME/~}"
    done
  fi
}

_dot_clean_claude() {
  local total_size=0
  local -a items=()

  # Old CLI versions (keep latest)
  local versions_dir="$HOME/.local/share/claude/versions"
  if [[ -d "$versions_dir" ]]; then
    local -a versions=()
    for dir in "$versions_dir"/*(N/); do
      versions+=("${dir:t}")
    done
    if (( ${#versions} > 1 )); then
      local latest
      latest=$(printf '%s\n' "${versions[@]}" | sort -V | tail -1)
      for dir in "$versions_dir"/*(N/); do
        [[ "${dir:t}" == "$latest" ]] && continue
        items+=("$dir")
        (( total_size += $(_dot_clean_dir_size "$dir") ))
      done
    fi
  fi

  # Debug logs
  local debug_logs="$HOME/.claude/logs/debug"
  if [[ -d "$debug_logs" ]]; then
    (( total_size += $(_dot_clean_dir_size "$debug_logs") ))
  fi

  if (( total_size == 0 )); then
    echo "  ✓ claude: clean"
    return
  fi

  local display=$(_dot_clean_format_size "$total_size")
  if _dot_clean_should_run "claude" "$display"; then
    for dir in "${items[@]}"; do
      rm -rf "$dir"
      echo "     removed old version ${dir:t}"
    done
    if [[ -d "$debug_logs" ]]; then
      find "$debug_logs" -type f -mtime +30 -delete 2>/dev/null
      echo "     cleaned debug logs >30d"
    fi
  fi
}

_dot_clean_claude-plugins() {
  local total_size=0
  local plugins_dir="$HOME/.claude/plugins"
  local settings_file="$HOME/repos/claude-config/settings.json"

  # 📦 Plugin cache
  local cache_dir="$plugins_dir/cache"
  if [[ -d "$cache_dir" ]]; then
    (( total_size += $(_dot_clean_dir_size "$cache_dir") ))
  fi

  # 📋 Plugin registry
  local registry="$plugins_dir/installed_plugins.json"
  if [[ -f "$registry" ]]; then
    local registry_plugins
    registry_plugins=$(jq -r '.plugins | keys | length' "$registry" 2>/dev/null)
    (( registry_plugins > 0 )) || registry_plugins=0
  fi

  # 🔧 enabledPlugins in settings.json
  local settings_plugins=0
  if [[ -f "$settings_file" ]]; then
    settings_plugins=$(jq -r '.enabledPlugins | keys | length' "$settings_file" 2>/dev/null)
    (( settings_plugins > 0 )) || settings_plugins=0
  fi

  if (( total_size == 0 )) && (( registry_plugins == 0 )) && (( settings_plugins == 0 )); then
    echo "  ✓ claude-plugins: clean"
    return
  fi

  local display=$(_dot_clean_format_size "$total_size")
  echo ""
  echo "  🧹 claude-plugins ($display)"
  echo "     cache: ${display}"
  echo "     registry: ${registry_plugins:-0} plugin(s)"
  echo "     settings.json: ${settings_plugins:-0} enabledPlugin(s)"

  if $dry_run; then
    echo "     [dry-run] Would clean"
    return
  fi

  if $auto_yes || _dot_ask "     Remove all plugins, cache, and enabledPlugins from settings.json?"; then
    # 🗑️ Clear plugin cache
    if [[ -d "$cache_dir" ]]; then
      rm -rf "$cache_dir"
      echo "     removed plugin cache"
    fi

    # 🗑️ Reset plugin registry
    if [[ -f "$registry" ]]; then
      echo '{"version":2,"plugins":{}}' > "$registry"
      echo "     reset installed_plugins.json"
    fi

    # 🗑️ Reset install counts
    local counts="$plugins_dir/install-counts-cache.json"
    if [[ -f "$counts" ]]; then
      echo '{}' > "$counts"
      echo "     reset install-counts-cache.json"
    fi

    # 🗑️ Remove enabledPlugins from settings.json
    if (( settings_plugins > 0 )) && [[ -f "$settings_file" ]]; then
      local tmp_settings
      tmp_settings=$(jq 'del(.enabledPlugins)' "$settings_file")
      echo "$tmp_settings" > "$settings_file"
      echo "     removed enabledPlugins from settings.json"
    fi

    echo "     ⚠️  Restart Claude Code for changes to take effect"
  fi
}

_dot_clean_home() {
  local zsh_items
  zsh_items=$(find "$HOME" -maxdepth 1 \( -name ".zsh*" -o -name "*.zsh" \) \
    -not -name ".zshenv" \
    -not -name ".zsh_history" \
    -not -name ".zsh_sessions" \
    -not -name ".zprofile" \
    -not -name ".zlogin" \
    -not -name ".zlogout" \
    2>/dev/null)

  if [[ -z "$zsh_items" ]]; then
    echo "  ✓ home: no stray ZSH files"
    return
  fi

  echo ""
  echo "  🧹 home (stray ZSH files)"
  echo "$zsh_items" | while read -r item; do
    echo "     - ${item/#$HOME/~}"
  done

  if $dry_run; then
    echo "     [dry-run] Would clean"
    return
  fi

  if $auto_yes || _dot_ask "     Remove these files?"; then
    echo "$zsh_items" | while read -r item; do
      rm -rf "$item"
    done
    echo "     Cleaned"
  fi
}

_dot_clean_yarn() {
  # macOS: ~/Library/Caches/Yarn, Linux: ~/.cache/yarn
  local cache_dir="$HOME/Library/Caches/Yarn"
  [[ -d "$cache_dir" ]] || cache_dir="$HOME/.cache/yarn"
  [[ -d "$cache_dir" ]] || { echo "  ✓ yarn: no cache"; return; }
  local size=$(_dot_clean_dir_size "$cache_dir")
  local display=$(_dot_clean_format_size "$size")
  if _dot_clean_should_run "yarn" "$display"; then
    rm -rf "$cache_dir"
    echo "     Cleaned"
  fi
}

_dot_clean_playwright() {
  local cache_dir="$HOME/.cache/ms-playwright"
  [[ -d "$cache_dir" ]] || { echo "  ✓ playwright: no cache"; return; }
  local size=$(_dot_clean_dir_size "$cache_dir")
  local display=$(_dot_clean_format_size "$size")
  if _dot_clean_should_run "playwright" "$display"; then
    rm -rf "$cache_dir"
    echo "     Cleaned"
  fi
}

_dot_clean_composer() {
  local cache_dir="$HOME/.cache/composer"
  [[ -d "$cache_dir" ]] || cache_dir="$HOME/.composer/cache"
  [[ -d "$cache_dir" ]] || { echo "  ✓ composer: no cache"; return; }
  local size=$(_dot_clean_dir_size "$cache_dir")
  local display=$(_dot_clean_format_size "$size")
  if _dot_clean_should_run "composer" "$display"; then
    rm -rf "$cache_dir"
    echo "     Cleaned"
  fi
}

_dot_clean_pip() {
  # macOS: ~/Library/Caches/pip, Linux: ~/.cache/pip
  local cache_dir="$HOME/Library/Caches/pip"
  [[ -d "$cache_dir" ]] || cache_dir="$HOME/.cache/pip"
  [[ -d "$cache_dir" ]] || { echo "  ✓ pip: no cache"; return; }
  local size=$(_dot_clean_dir_size "$cache_dir")
  local display=$(_dot_clean_format_size "$size")
  if _dot_clean_should_run "pip" "$display"; then
    rm -rf "$cache_dir"
    echo "     Cleaned"
  fi
}

_dot_clean_tmp() {
  local tmp_dir="$HOME/tmp"
  [[ -d "$tmp_dir" ]] || { echo "  ✓ tmp: no ~/tmp"; return; }
  local total_size=0
  local -a old_dirs=()
  for dir in "$tmp_dir"/claude-*-cwd(N/); do
    if [[ $(find "$dir" -maxdepth 0 -mtime +7 2>/dev/null) ]]; then
      old_dirs+=("$dir")
      (( total_size += $(_dot_clean_dir_size "$dir") ))
    fi
  done
  if (( ${#old_dirs} == 0 )); then
    echo "  ✓ tmp: no stale session dirs"
    return
  fi
  local display=$(_dot_clean_format_size "$total_size")
  if _dot_clean_should_run "tmp (${#old_dirs} claude sessions >7d)" "$display"; then
    for dir in "${old_dirs[@]}"; do
      rm -rf "$dir"
    done
    echo "     Cleaned ${#old_dirs} dirs"
  fi
}

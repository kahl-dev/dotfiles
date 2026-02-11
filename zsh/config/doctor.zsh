#!/usr/bin/env zsh
# 🩺 dot doctor — diagnose and fix common dotfiles issues

_dot_doctor() {
  local fix=false
  local auto_yes=false
  local issues=0
  local categories=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --fix) fix=true; shift ;;
      --yes) auto_yes=true; shift ;;
      *) echo "dot doctor: unknown option '$1'" >&2; return 1 ;;
    esac
  done

  if $auto_yes && ! $fix; then
    echo "dot doctor: --yes requires --fix" >&2
    return 1
  fi

  echo ""
  echo "${_dot_bold}dot doctor${_dot_reset} — dotfiles health check"
  echo ""

  # NOTE: check_issues is modified by child functions via ZSH dynamic scoping.
  # Each check function sets check_issues to its issue count (0 = clean).
  # Do NOT declare check_issues as local inside check functions.
  local check_issues
  for check in \
    _dot_doctor_path_duplicates \
    _dot_doctor_path_invalid \
    _dot_doctor_dotfiles_dirty \
    _dot_doctor_disk_space \
    _dot_doctor_required_tools \
    _dot_doctor_ssh_permissions \
    _dot_doctor_zinit_orphans \
    _dot_doctor_dead_symlinks \
    _dot_doctor_tmux_resurrect \
    _dot_doctor_tmux_plugin_mismatch \
    _dot_doctor_fnm_multishells \
    _dot_doctor_nvim_swap \
    _dot_doctor_mise_duplicates \
    _dot_doctor_dotbot_pycache \
    _dot_doctor_brew_cache \
    _dot_doctor_launchagent_health \
    _dot_doctor_orphaned_configs \
    _dot_doctor_claude_old_versions \
    _dot_doctor_ssh_agent \
    _dot_doctor_dotfiles_symlinks \
    _dot_doctor_shell_startup_time; do

    check_issues=0
    $check
    if (( check_issues > 0 )); then
      (( categories++ ))
      (( issues += check_issues ))
    fi
  done

  echo ""
  if (( issues > 0 )); then
    local category_word="categories"
    (( categories == 1 )) && category_word="category"
    echo "⚠️  Found $issues issue(s) across $categories $category_word"
    if ! $fix; then
      echo "   Run ${_dot_bold}dot doctor --fix${_dot_reset} to resolve interactively"
    fi
  else
    echo "✅ No issues found"
  fi
  echo ""
}

# ── Helper: portable file permissions (macOS vs Linux stat) ──────────────────
_dot_stat_perms() {
  if is_macos; then
    stat -f %Lp "$1" 2>/dev/null
  else
    stat -c %a "$1" 2>/dev/null
  fi
}

# ── Helper: prompt or auto-fix ───────────────────────────────────────────────
_dot_doctor_should_fix() {
  $fix || return 1
  $auto_yes && return 0
  _dot_ask "$1"
}

# ── 8. PATH duplicates ────────────────────────────────────────────────────────
_dot_doctor_path_duplicates() {
  local -a seen=()
  local -a duplicates=()
  local -a path_entries=("${(@s/:/)PATH}")
  local dir

  for dir in "${path_entries[@]}"; do
    if (( ${seen[(Ie)$dir]} )); then
      (( ${duplicates[(Ie)$dir]} )) || duplicates+=("$dir")
    else
      seen+=("$dir")
    fi
  done

  if (( ${#duplicates} == 0 )); then
    echo "  ✓ PATH duplicates: none"
    return
  fi

  check_issues=${#duplicates}
  echo "  ⚠️  PATH duplicates: ${#duplicates} duplicate(s)"
  for dir in "${duplicates[@]}"; do
    echo "     - $dir"
  done
  echo "     → Add 'typeset -U PATH' to .zshenv"
}

# ── 9. PATH invalid entries ──────────────────────────────────────────────────
_dot_doctor_path_invalid() {
  local -a invalid=()
  local -a path_entries=("${(@s/:/)PATH}")
  local dir

  for dir in "${path_entries[@]}"; do
    [[ -z "$dir" ]] && continue
    [[ -d "$dir" ]] || invalid+=("$dir")
  done

  if (( ${#invalid} == 0 )); then
    echo "  ✓ PATH entries: all valid"
    return
  fi

  check_issues=${#invalid}
  echo "  ⚠️  PATH invalid: ${#invalid} non-existent dir(s)"
  for dir in "${invalid[@]}"; do
    echo "     - ${dir/#$HOME/~}"
  done
}

# ── 10. Shell startup time ───────────────────────────────────────────────────
_dot_doctor_shell_startup_time() {
  local elapsed
  elapsed=$(perl -MTime::HiRes=time -e '
    my $start = time();
    system("zsh", "-i", "-c", "exit");
    printf "%.0f\n", (time() - $start) * 1000;
  ' 2>/dev/null)

  if [[ -z "$elapsed" ]]; then
    echo "  ✓ Shell startup: unable to measure"
    return
  fi

  if (( elapsed <= 800 )); then
    echo "  ✓ Shell startup: ${elapsed}ms"
    return
  fi

  check_issues=1
  echo "  ⚠️  Shell startup: ${elapsed}ms (threshold: 800ms)"
  echo "     → Run 'zprof' to profile (add 'zmodload zsh/zprof' to .zshrc top)"
}

# ── 11. Dotfiles git dirty ───────────────────────────────────────────────────
_dot_doctor_dotfiles_dirty() {
  if [[ ! -d "$DOTFILES/.git" ]]; then
    echo "  ✓ Dotfiles repo: not a git repo"
    return
  fi

  local dirty
  dirty=$(git -C "$DOTFILES" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

  if (( dirty == 0 )); then
    echo "  ✓ Dotfiles repo: clean"
    return
  fi

  check_issues=$dirty
  echo "  ⚠️  Dotfiles repo: $dirty uncommitted change(s)"
  echo "     → cd $DOTFILES && git status"
}

# ── 12. Disk space ──────────────────────────────────────────────────────────
_dot_doctor_disk_space() {
  # Use df -k (POSIX portable) and convert to GB
  local free_kb free_gb
  free_kb=$(df -k "$HOME" 2>/dev/null | awk 'NR==2 {print $4}')
  [[ -n "$free_kb" ]] && free_gb=$(( free_kb / 1048576 ))

  if [[ -z "$free_gb" ]]; then
    echo "  ✓ Disk space: unable to check"
    return
  fi

  if (( free_gb >= 10 )); then
    echo "  ✓ Disk space: ${free_gb}GB free"
    return
  fi

  check_issues=1
  echo "  ⚠️  Disk space: ${free_gb}GB free (threshold: 10GB)"
  echo "     → Run 'dot clean --dry-run' to find reclaimable space"
}

# ── 13. Tmux plugin mismatch ────────────────────────────────────────────────
_dot_doctor_tmux_plugin_mismatch() {
  local tmux_conf="$DOTFILES/tmux/tmux.conf"
  local plugins_dir="$DOTFILES/tmux/plugins"
  [[ -f "$tmux_conf" && -d "$plugins_dir" ]] || return 0

  # Parse declared plugins from tmux.conf (uncommented set -g @plugin lines)
  local -a declared=()
  local line repo_name
  while IFS= read -r line; do
    # Extract repo name: 'user/repo' → repo
    repo_name="${line##*/}"
    repo_name="${repo_name%%\'*}"
    repo_name="${repo_name%%\"*}"
    declared+=("$repo_name")
  done < <(grep -E "^set -g @plugin " "$tmux_conf" 2>/dev/null | sed "s/.*@plugin ['\"]*//" | sed "s/['\"].*//")

  # Compare installed dirs with declared
  local -a orphans=()
  local dir dir_name
  for dir in "$plugins_dir"/*(N/); do
    dir_name="${dir:t}"
    [[ "$dir_name" == "tpm" ]] && continue
    if (( ! ${declared[(Ie)$dir_name]} )); then
      orphans+=("$dir")
    fi
  done

  if (( ${#orphans} == 0 )); then
    echo "  ✓ Tmux plugins: all match tmux.conf"
    return
  fi

  check_issues=${#orphans}
  echo "  ⚠️  Tmux plugins: ${#orphans} orphan(s) not in tmux.conf"
  for dir in "${orphans[@]}"; do
    echo "     - ${dir:t}"
  done

  if _dot_doctor_should_fix "Remove ${#orphans} orphaned tmux plugin(s)?"; then
    for dir in "${orphans[@]}"; do
      rm -rf "$dir"
      echo "     removed ${dir:t}"
    done
  fi
}

# ── 14. Brew cache size ─────────────────────────────────────────────────────
_dot_doctor_brew_cache() {
  # macOS: ~/Library/Caches/Homebrew, Linux: ~/.cache/Homebrew
  local cache_dir="$HOME/Library/Caches/Homebrew"
  [[ -d "$cache_dir" ]] || cache_dir="$HOME/.cache/Homebrew"
  [[ -d "$cache_dir" ]] || return 0

  local size_bytes
  size_bytes=$(du -sk "$cache_dir" 2>/dev/null | awk '{print $1}')
  local size_mb=$(( size_bytes / 1024 ))

  if (( size_mb < 500 )); then
    echo "  ✓ Brew cache: ${size_mb}MB"
    return
  fi

  check_issues=1
  local size_display
  if (( size_mb >= 1024 )); then
    size_display="$(( size_mb / 1024 )).$(( (size_mb % 1024) * 10 / 1024 ))GB"
  else
    size_display="${size_mb}MB"
  fi
  echo "  ⚠️  Brew cache: $size_display (threshold: 500MB)"

  if _dot_doctor_should_fix "Clean Homebrew cache (brew cleanup --prune=7)?"; then
    brew cleanup --prune=7
    echo "     Homebrew cache cleaned"
  fi
}

# ── 15. LaunchAgent health ───────────────────────────────────────────────────
_dot_doctor_launchagent_health() {
  is_macos || return 0
  local agents_dir="$HOME/Library/LaunchAgents"
  [[ -d "$agents_dir" ]] || return 0

  local -a broken=()
  local plist label
  for plist in "$agents_dir"/*.plist(N); do
    label="${plist:t:r}"
    # Skip system/vendor agents
    [[ "$label" == com.apple.* ]] && continue
    [[ "$label" == homebrew.* ]] && continue
    [[ "$label" == com.google.* ]] && continue
    [[ "$label" == dev.kahl.kanata* ]] && continue

    # Extract ProgramArguments using PlistBuddy
    local program
    program=$(/usr/libexec/PlistBuddy -c "Print :ProgramArguments:0" "$plist" 2>/dev/null)
    if [[ -n "$program" && ! -e "$program" ]]; then
      broken+=("$label → $program")
    fi
  done

  if (( ${#broken} == 0 )); then
    echo "  ✓ LaunchAgents: all scripts exist"
    return
  fi

  check_issues=${#broken}
  echo "  ⚠️  LaunchAgents: ${#broken} broken agent(s)"
  for entry in "${broken[@]}"; do
    echo "     - $entry"
  done
}

# ── 16. Orphaned configs ────────────────────────────────────────────────────
_dot_doctor_orphaned_configs() {
  local config_dir="$HOME/.config"
  [[ -d "$config_dir" ]] || return 0

  # Known orphan patterns: apps that are no longer installed
  local -a orphan_candidates=(fish shell_gpt fabric iterm2)
  local -a found=()
  local name

  for name in "${orphan_candidates[@]}"; do
    if [[ -d "$config_dir/$name" ]]; then
      # Verify app is not installed
      case "$name" in
        fish)     command_exists fish     || found+=("$name") ;;
        shell_gpt) command_exists sgpt    || found+=("$name") ;;
        fabric)   command_exists fabric   || found+=("$name") ;;
        iterm2)   is_macos && { [[ -d "/Applications/iTerm.app" ]] || found+=("$name"); } ;;
      esac
    fi
  done

  if (( ${#found} == 0 )); then
    echo "  ✓ Orphaned configs: none"
    return
  fi

  check_issues=${#found}
  echo "  ⚠️  Orphaned configs: ${#found} dir(s) for uninstalled apps"
  for name in "${found[@]}"; do
    echo "     - ~/.config/$name"
  done

  if _dot_doctor_should_fix "Remove ${#found} orphaned config dir(s)?"; then
    for name in "${found[@]}"; do
      rm -rf "$config_dir/$name"
      echo "     removed ~/.config/$name"
    done
  fi
}

# ── 17. Required tools ──────────────────────────────────────────────────────
_dot_doctor_required_tools() {
  local -a missing=()
  local tool

  for tool in git mise tmux nvim brew; do
    command_exists "$tool" || missing+=("$tool")
  done

  if (( ${#missing} == 0 )); then
    echo "  ✓ Required tools: all present"
    return
  fi

  check_issues=${#missing}
  echo "  ⚠️  Required tools: ${#missing} missing"
  for tool in "${missing[@]}"; do
    echo "     - $tool"
  done
}

# ── 18. SSH permissions ──────────────────────────────────────────────────────
_dot_doctor_ssh_permissions() {
  local ssh_dir="$HOME/.ssh"
  [[ -d "$ssh_dir" ]] || return 0

  local -a bad_perms=()

  # Check directory permissions
  local dir_perms
  dir_perms=$(_dot_stat_perms "$ssh_dir")
  if [[ "$dir_perms" != "700" ]]; then
    bad_perms+=("~/.ssh/ is $dir_perms (should be 700)")
  fi

  # Check private key permissions
  local key
  for key in "$ssh_dir"/id_*(N) "$ssh_dir"/*.pem(N); do
    [[ -f "$key" ]] || continue
    # Skip public keys
    [[ "$key" == *.pub ]] && continue
    local key_perms
    key_perms=$(_dot_stat_perms "$key")
    if [[ "$key_perms" != "600" ]]; then
      bad_perms+=("${key/#$HOME/~} is $key_perms (should be 600)")
    fi
  done

  if (( ${#bad_perms} == 0 )); then
    echo "  ✓ SSH permissions: correct"
    return
  fi

  check_issues=${#bad_perms}
  echo "  ⚠️  SSH permissions: ${#bad_perms} issue(s)"
  for entry in "${bad_perms[@]}"; do
    echo "     - $entry"
  done

  if _dot_doctor_should_fix "Fix SSH permissions?"; then
    chmod 700 "$ssh_dir"
    for key in "$ssh_dir"/id_*(N) "$ssh_dir"/*.pem(N); do
      [[ -f "$key" && "$key" != *.pub ]] && chmod 600 "$key"
    done
    echo "     SSH permissions fixed"
  fi
}

# ── 19. Claude old CLI versions ──────────────────────────────────────────────
_dot_doctor_claude_old_versions() {
  local versions_dir="$HOME/.local/share/claude/versions"
  [[ -d "$versions_dir" ]] || return 0

  local -a versions=()
  local dir
  for dir in "$versions_dir"/*(N/); do
    versions+=("${dir:t}")
  done

  if (( ${#versions} <= 1 )); then
    echo "  ✓ Claude versions: ${#versions} installed"
    return
  fi

  # Find latest version using sort -V (version sort)
  local latest
  latest=$(printf '%s\n' "${versions[@]}" | sort -V | tail -1)
  local removable=$(( ${#versions} - 1 ))

  # Calculate total size of old versions
  local total_size=0
  for dir in "$versions_dir"/*(N/); do
    [[ "${dir:t}" == "$latest" ]] && continue
    local dir_size
    dir_size=$(du -sk "$dir" 2>/dev/null | awk '{print $1}')
    (( total_size += dir_size ))
  done
  local size_mb=$(( total_size / 1024 ))

  check_issues=$removable
  echo "  ⚠️  Claude versions: ${#versions} installed (${size_mb}MB reclaimable, keeping $latest)"
  for v in "${versions[@]}"; do
    [[ "$v" == "$latest" ]] && echo "     - $v (latest)" || echo "     - $v"
  done

  if _dot_doctor_should_fix "Remove $removable old Claude CLI version(s)?"; then
    for dir in "$versions_dir"/*(N/); do
      [[ "${dir:t}" == "$latest" ]] && continue
      rm -rf "$dir"
      echo "     removed ${dir:t}"
    done
  fi
}

# ── 1. Zinit orphan plugins ──────────────────────────────────────────────────
_dot_doctor_zinit_orphans() {
  local zinit_plugins="${ZINIT_ROOT:-$HOME/.local/share/zinit}/plugins"
  [[ -d "$zinit_plugins" ]] || return 0

  # Collect declared plugins from all config files
  local -a declared=()
  local plugin_name
  while IFS= read -r plugin_name; do
    # Strip quotes and trailing whitespace
    plugin_name="${plugin_name//\"/}"
    plugin_name="${plugin_name//\'/}"
    plugin_name="${plugin_name%%[[:space:]]*}"
    # Only accept user/repo format (skip snippets, malformed entries)
    [[ "$plugin_name" == */* ]] && declared+=("${plugin_name//\//---}")
  done < <(grep -h -E '^\s*zinit (light|load) ' "$DOTFILES/zsh/config/"*.zsh 2>/dev/null \
    | grep -v '^\s*#' \
    | sed -E 's/.*zinit (light|load) //')

  # Compare with installed dirs
  local -a orphans=()
  local dir dir_name
  for dir in "$zinit_plugins"/*(N/); do
    dir_name="${dir:t}"
    [[ "$dir_name" == "_local---zinit" ]] && continue
    if (( ! ${declared[(Ie)$dir_name]} )); then
      orphans+=("$dir")
    fi
  done

  if (( ${#orphans} == 0 )); then
    echo "  ✓ Zinit plugins: no orphans"
    return
  fi

  check_issues=${#orphans}
  echo "  ⚠️  Zinit plugins: ${#orphans} orphan(s)"
  for dir in "${orphans[@]}"; do
    echo "     - ${dir:t}"
  done

  if _dot_doctor_should_fix "Remove ${#orphans} orphaned zinit plugin(s)?"; then
    for dir in "${orphans[@]}"; do
      rm -rf "$dir"
      echo "     removed ${dir:t}"
    done
  fi
}

# ── 2. Dead symlinks ────────────────────────────────────────────────────────
_dot_doctor_dead_symlinks() {
  local -a broken=()
  local link

  # Scan HOME (depth 1), ~/.config, ~/.claude
  for link in "$HOME"/*(N@) "$HOME"/.config/**/*(N@) "$HOME"/.claude/**/*(N@); do
    [[ -e "$link" ]] || broken+=("$link")
  done

  if (( ${#broken} == 0 )); then
    echo "  ✓ Symlinks: no broken links"
    return
  fi

  check_issues=${#broken}
  echo "  ⚠️  Symlinks: ${#broken} broken link(s)"
  for link in "${broken[@]}"; do
    local target
    target=$(readlink "$link" 2>/dev/null)
    echo "     - ${link/#$HOME/~} -> $target"
  done

  if _dot_doctor_should_fix "Remove ${#broken} broken symlink(s)?"; then
    for link in "${broken[@]}"; do
      rm -f "$link"
      echo "     removed ${link/#$HOME/~}"
    done
  fi
}

# ── 3. Tmux resurrect snapshots ─────────────────────────────────────────────
_dot_doctor_tmux_resurrect() {
  local resurrect_dir="$DOTFILES/tmux/resurrect"
  [[ -d "$resurrect_dir" ]] || return 0

  local count
  count=$(find "$resurrect_dir" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')

  if (( count <= 30 )); then
    echo "  ✓ Tmux resurrect: $count snapshot(s)"
    return
  fi

  local removable=$(( count - 30 ))
  check_issues=$removable
  echo "  ⚠️  Tmux resurrect: $count snapshots ($removable removable, keeping 30 newest)"

  if _dot_doctor_should_fix "Remove $removable oldest tmux resurrect snapshot(s)?"; then
    ls -t "$resurrect_dir"/* 2>/dev/null \
      | tail -n "$removable" \
      | while IFS= read -r file; do
          rm -f "$file"
        done
    echo "     removed $removable snapshot(s)"
  fi
}

# ── 4. fnm multishells ──────────────────────────────────────────────────────
_dot_doctor_fnm_multishells() {
  local -a dirs_to_check=(
    "$HOME/.local/state/fnm_multishells"
    "$HOME/.cache/fnm_multishells"
  )
  local total=0
  local -a found_dirs=()

  for dir in "${dirs_to_check[@]}"; do
    if [[ -d "$dir" ]]; then
      local count
      count=$(find "$dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
      (( total += count ))
      (( count > 0 )) && found_dirs+=("$dir")
    fi
  done

  if (( total <= 100 )); then
    local dir_word="directories"
    (( total == 1 )) && dir_word="directory"
    echo "  ✓ fnm multishells: $total $dir_word"
    return
  fi

  check_issues=$total
  echo "  ⚠️  fnm multishells: $total directories (threshold: 100)"

  if _dot_doctor_should_fix "Remove all fnm multishell directories?"; then
    for dir in "${found_dirs[@]}"; do
      rm -rf "$dir"/*
      echo "     cleaned $dir"
    done
  fi
}

# ── 5. Neovim swap files ────────────────────────────────────────────────────
_dot_doctor_nvim_swap() {
  local swap_dir="$HOME/.local/state/nvim/swap"
  [[ -d "$swap_dir" ]] || return 0

  local count
  count=$(find "$swap_dir" -maxdepth 1 \( -name "*.swp" -o -name "*.swo" \) 2>/dev/null | wc -l | tr -d ' ')

  if (( count == 0 )); then
    echo "  ✓ Neovim swap: no swap files"
    return
  fi

  check_issues=$count
  echo "  ⚠️  Neovim swap: $count file(s)"

  if _dot_doctor_should_fix "Remove $count neovim swap file(s)?"; then
    find "$swap_dir" -maxdepth 1 \( -name "*.swp" -o -name "*.swo" \) -delete 2>/dev/null
    echo "     removed $count swap file(s)"
  fi
}

# ── 6. Mise duplicates (report only) ────────────────────────────────────────
_dot_doctor_mise_duplicates() {
  if ! command_exists mise; then
    echo "  ✓ Mise duplicates: mise not installed (skip)"
    return
  fi

  local -a duplicates=()
  local tool

  # Check if mise-managed tools also exist via brew or system
  for tool in node python ruby go java; do
    if mise which "$tool" &>/dev/null; then
      local mise_path brew_path
      mise_path=$(mise which "$tool" 2>/dev/null)
      if command_exists brew; then
        brew_path=$(brew --prefix 2>/dev/null)/bin/$tool
        if [[ -x "$brew_path" && "$mise_path" != "$brew_path" ]]; then
          duplicates+=("$tool (mise: $mise_path, brew: $brew_path)")
        fi
      fi
    fi
  done

  if (( ${#duplicates} == 0 )); then
    echo "  ✓ Mise duplicates: no overlapping installations"
    return
  fi

  check_issues=${#duplicates}
  echo "  ⚠️  Mise duplicates: ${#duplicates} tool(s) installed via both mise and brew"
  for dup in "${duplicates[@]}"; do
    echo "     - $dup"
  done
  echo "     → Consider: brew uninstall <tool> (mise manages these)"
}

# ── 7. Dotbot __pycache__ ───────────────────────────────────────────────────
_dot_doctor_dotbot_pycache() {
  local dotbot_dir="$DOTFILES/meta/dotbot"
  [[ -d "$dotbot_dir" ]] || return 0

  local -a pycache_dirs=()
  local dir
  while IFS= read -r dir; do
    pycache_dirs+=("$dir")
  done < <(find "$dotbot_dir" -type d -name "__pycache__" 2>/dev/null)

  if (( ${#pycache_dirs} == 0 )); then
    echo "  ✓ Dotbot pycache: clean"
    return
  fi

  check_issues=${#pycache_dirs}
  local pycache_word="directories"
  (( ${#pycache_dirs} == 1 )) && pycache_word="directory"
  echo "  ⚠️  Dotbot pycache: ${#pycache_dirs} __pycache__ $pycache_word"

  if _dot_doctor_should_fix "Remove ${#pycache_dirs} __pycache__ $pycache_word?"; then
    for dir in "${pycache_dirs[@]}"; do
      rm -rf "$dir"
      echo "     removed ${dir/#$DOTFILES/\$DOTFILES}"
    done
  fi
}

# ── SSH agent health ─────────────────────────────────────────────────────
_dot_doctor_ssh_agent() {
  ssh-add -l &>/dev/null
  local exit_code=$?
  if (( exit_code == 0 )); then
    local key_count
    key_count=$(ssh-add -l 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✓ SSH agent: ${key_count} key(s) loaded"
  elif (( exit_code == 2 )); then
    check_issues=1
    echo "  ⚠️  SSH agent: not running"
  else
    check_issues=1
    echo "  ⚠️  SSH agent: no identities loaded"
  fi
}

# ── Dotfiles symlink health ──────────────────────────────────────────────
_dot_doctor_dotfiles_symlinks() {
  local -a broken=()
  local link
  for link in \
    "$HOME/.zshenv" \
    "$HOME/.gitconfig" \
    "$HOME/.gitignore_global" \
    "$HOME/.config/starship.toml" \
    "$HOME/.config/mise/config.toml" \
    "$HOME/.config/nvim" \
    "$HOME/.config/bat" \
    "$HOME/.config/lazygit" \
    "$HOME/.tmux.conf"; do
    if [[ -L "$link" && ! -e "$link" ]]; then
      broken+=("${link/#$HOME/~}")
    fi
  done
  if (( ${#broken} == 0 )); then
    echo "  ✓ Dotfiles symlinks: all valid"
    return
  fi
  check_issues=${#broken}
  echo "  ⚠️  Dotfiles symlinks: ${#broken} broken"
  for link in "${broken[@]}"; do
    echo "     - $link"
  done
}

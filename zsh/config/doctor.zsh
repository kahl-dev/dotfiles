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
  echo "\033[1mdot doctor\033[0m — dotfiles health check"
  echo ""

  # NOTE: check_issues is modified by child functions via ZSH dynamic scoping.
  # Each check function sets check_issues to its issue count (0 = clean).
  # Do NOT declare check_issues as local inside check functions.
  local check_issues
  for check in \
    _dot_doctor_zinit_orphans \
    _dot_doctor_dead_symlinks \
    _dot_doctor_tmux_resurrect \
    _dot_doctor_fnm_multishells \
    _dot_doctor_nvim_swap \
    _dot_doctor_mise_duplicates \
    _dot_doctor_dotbot_pycache; do

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
      echo "   Run \033[1mdot doctor --fix\033[0m to resolve interactively"
    fi
  else
    echo "✅ No issues found"
  fi
  echo ""
}

# ── Helper: prompt or auto-fix ───────────────────────────────────────────────
_dot_doctor_should_fix() {
  $fix || return 1
  $auto_yes && return 0
  _dot_ask "$1"
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
      brew_path=$(brew --prefix 2>/dev/null)/bin/$tool

      if [[ -x "$brew_path" && "$mise_path" != "$brew_path" ]]; then
        duplicates+=("$tool (mise: $mise_path, brew: $brew_path)")
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

#!/usr/bin/env zsh
# dot — unified dotfiles CLI
# Usage: dot [command] [subcommand] [args...]
# No args → fzf interactive menu
#
# Future enhancements (deferred from v1, reviewed by multi-agent debate):
#   - dot doctor     — diagnose common issues (broken symlinks, missing deps,
#                      stale zinit cache, $DOTFILES integrity, brew doctor)
#   - dot uninstall  — unified uninstall (currently delegated to scripts/uninstall.sh)
#   - dot status     — show dotfiles health (last update, dirty state, outdated packages)
#   - dot sync       — pull latest dotfiles + run install-profile
#   - Split into multiple files if this grows beyond ~500 lines
#   - Registry/dispatcher drift detection (automated consistency check)
#   - Testing framework for critical commands (zunit or bats)

# Clear any conflicting alias
unalias dot 2>/dev/null

# Guard: $DOTFILES must be set
if [[ -z "$DOTFILES" ]]; then
  echo "dot: \$DOTFILES is not set" >&2
  return 1
fi

# ── Command Registry ──────────────────────────────────────────────────────────
# Format: DOT_COMMANDS[category/action]="description"
typeset -gA DOT_COMMANDS
DOT_COMMANDS=(
  "install/profile"   "Install a dotbot profile"
  "install/standalone" "Install a standalone ingredient"
  "brew/update"       "Update, upgrade & cleanup Homebrew"
  "brew/dump"         "Export installed packages to Brewfile"
  "shell/reload"      "Reload ZSH configuration"
  "shell/reset"       "Reset zinit plugins and reload"
  "shell/clean"       "Remove stray ZSH files from HOME"
  "nvim/reset"        "Reset lazy.nvim packages"
  "update"            "Interactive update wizard"
  "rb/start"          "Start Remote Bridge"
  "rb/stop"           "Stop Remote Bridge"
  "rb/restart"        "Restart Remote Bridge"
  "rb/status"         "Remote Bridge status"
  "rb/logs"           "Remote Bridge logs"
  "edit"              "Open dotfiles in editor"
  "color-test"        "Run terminal color test"
  "help"              "Show all commands"
)

# ── Main Function ─────────────────────────────────────────────────────────────
dot() {
  if [[ $# -eq 0 ]]; then
    if command_exists fzf; then
      _dot_fzf_menu
    else
      _dot_help
    fi
    return
  fi

  local command="$1"
  shift

  case "$command" in
    install)
      local subcommand="${1:-}"
      [[ -n "$subcommand" ]] && shift
      case "$subcommand" in
        profile)
          local name="${1:-}"
          if [[ -z "$name" ]]; then
            if command_exists fzf; then
              name=$(_dot_pick_recipe)
              [[ -z "$name" ]] && return 0
            else
              echo "Usage: dot install profile <name>" >&2
              echo "Available: $(ls "$DOTFILES/meta/recipes/" 2>/dev/null | tr '\n' ' ')" >&2
              return 1
            fi
          fi
          if [[ "$name" == */* || "$name" == *..* ]]; then
            echo "dot install profile: invalid name '$name'" >&2
            return 1
          fi
          if [[ ! -f "$DOTFILES/meta/recipes/$name" ]]; then
            echo "dot install profile: '$name' not found in $DOTFILES/meta/recipes/" >&2
            return 1
          fi
          echo "Installing profile: $name"
          "$DOTFILES/install-profile" "$name"
          ;;
        standalone)
          local name="${1:-}"
          if [[ -z "$name" ]]; then
            if command_exists fzf; then
              name=$(_dot_pick_ingredient)
              [[ -z "$name" ]] && return 0
            else
              echo "Usage: dot install standalone <name>" >&2
              echo "Available: $(ls "$DOTFILES/meta/ingredients/"*.yaml 2>/dev/null | xargs -I{} basename {} .yaml | tr '\n' ' ')" >&2
              return 1
            fi
          fi
          if [[ "$name" == */* || "$name" == *..* ]]; then
            echo "dot install standalone: invalid name '$name'" >&2
            return 1
          fi
          if [[ ! -f "$DOTFILES/meta/ingredients/${name}.yaml" ]]; then
            echo "dot install standalone: '$name' not found in $DOTFILES/meta/ingredients/" >&2
            return 1
          fi
          echo "Installing ingredient: $name"
          "$DOTFILES/install-standalone" "$name"
          ;;
        "")
          echo "dot install: missing subcommand" >&2
          echo "Usage: dot install [profile|standalone] <name>" >&2
          return 1
          ;;
        *)
          echo "dot install: unknown subcommand '$subcommand'" >&2
          echo "Usage: dot install [profile|standalone] <name>" >&2
          return 1
          ;;
      esac
      ;;

    brew)
      local subcommand="${1:-}"
      [[ -n "$subcommand" ]] && shift
      case "$subcommand" in
        update)
          if ! command_exists brew; then
            echo "dot brew: brew is not installed" >&2
            return 1
          fi
          echo "Updating Homebrew..."
          brew update && brew upgrade && brew cleanup -s
          ;;
        dump)
          if ! command_exists brew; then
            echo "dot brew: brew is not installed" >&2
            return 1
          fi
          if [[ -z "${HOMEBREW_BUNDLE_FILE_GLOBAL:-}" ]]; then
            echo "dot brew dump: \$HOMEBREW_BUNDLE_FILE_GLOBAL is not set" >&2
            return 1
          fi
          echo "Exporting to $HOMEBREW_BUNDLE_FILE_GLOBAL"
          brew bundle dump --force --describe --file="$HOMEBREW_BUNDLE_FILE_GLOBAL"
          ;;
        "")
          echo "dot brew: missing subcommand" >&2
          echo "Usage: dot brew [update|dump]" >&2
          return 1
          ;;
        *)
          echo "dot brew: unknown subcommand '$subcommand'" >&2
          echo "Usage: dot brew [update|dump]" >&2
          return 1
          ;;
      esac
      ;;

    shell)
      local subcommand="${1:-}"
      [[ -n "$subcommand" ]] && shift
      case "$subcommand" in
        reload)
          echo "Reloading ZSH..."
          source "${ZDOTDIR:-$HOME}/.zshrc"
          ;;
        reset)
          if ! _dot_ask "This will delete all zinit plugins and reload. Continue?"; then
            echo "Aborted."
            return 0
          fi
          echo "Resetting zinit plugins..."
          rm -rf "${ZINIT_ROOT:-$HOME/.local/share/zinit}"/plugins
          rm -rf "${ZINIT_ROOT:-$HOME/.local/share/zinit}"/snippets
          rm -rf "${ZINIT_ROOT:-$HOME/.local/share/zinit}"/completions
          echo "Reloading ZSH..."
          source "${ZDOTDIR:-$HOME}/.zshrc"
          ;;
        clean)
          _dot_clean_home
          ;;
        "")
          echo "dot shell: missing subcommand" >&2
          echo "Usage: dot shell [reload|reset|clean]" >&2
          return 1
          ;;
        *)
          echo "dot shell: unknown subcommand '$subcommand'" >&2
          echo "Usage: dot shell [reload|reset|clean]" >&2
          return 1
          ;;
      esac
      ;;

    nvim)
      local subcommand="${1:-}"
      [[ -n "$subcommand" ]] && shift
      case "$subcommand" in
        reset)
          if ! _dot_ask "This will delete all lazy.nvim packages and cache. Continue?"; then
            echo "Aborted."
            return 0
          fi
          echo "Resetting lazy.nvim packages..."
          rm -rf ~/.local/share/nvim/lazy
          rm -rf ~/.local/state/nvim/lazy
          rm -rf ~/.cache/nvim
          echo "Neovim package cache cleared."
          ;;
        "")
          echo "dot nvim: missing subcommand" >&2
          echo "Usage: dot nvim reset" >&2
          return 1
          ;;
        *)
          echo "dot nvim: unknown subcommand '$subcommand'" >&2
          echo "Usage: dot nvim reset" >&2
          return 1
          ;;
      esac
      ;;

    rb)
      local subcommand="${1:-}"
      [[ -n "$subcommand" ]] && shift
      local rb_bin="$DOTFILES/remote-bridge/bin/remote-bridge"
      if [[ ! -x "$rb_bin" ]]; then
        echo "dot rb: Remote Bridge not installed" >&2
        echo "Run: dot install standalone remote-bridge" >&2
        return 1
      fi
      case "$subcommand" in
        start|stop|restart|status|logs)
          "$rb_bin" "$subcommand" "$@"
          ;;
        "")
          echo "dot rb: missing subcommand" >&2
          echo "Usage: dot rb [start|stop|restart|status|logs]" >&2
          return 1
          ;;
        *)
          echo "dot rb: unknown subcommand '$subcommand'" >&2
          echo "Usage: dot rb [start|stop|restart|status|logs]" >&2
          return 1
          ;;
      esac
      ;;

    update)
      _dot_update_wizard "$@"
      ;;

    edit)
      ${EDITOR:-nvim} "$DOTFILES"
      ;;

    color-test)
      zsh "$DOTFILES/scripts/run_color_test.zsh"
      ;;

    help)
      _dot_help
      ;;

    *)
      echo "dot: unknown command '$command'" >&2
      echo ""
      _dot_help
      return 1
      ;;
  esac
}

# ── fzf Interactive Menu ─────────────────────────────────────────────────────
_dot_fzf_menu() {
  local entries=()
  local key description

  for key in ${(ko)DOT_COMMANDS}; do
    description="${DOT_COMMANDS[$key]}"
    entries+=("$(printf "%-24s %s\t%s" "$key" "$description" "$key")")
  done

  local selection
  selection=$(printf '%s\n' "${entries[@]}" | fzf --ansi --with-nth=1 --delimiter=$'\t' --prompt="dot> " --header="dotfiles commands" --reverse)
  [[ -z "$selection" ]] && return 0

  # Extract the key (after tab delimiter)
  key="${selection##*$'\t'}"

  # Split key into command args
  local category="${key%%/*}"
  local action="${key#*/}"

  if [[ "$category" == "$action" ]]; then
    # Top-level command (update, edit, etc.)
    dot "$category"
  else
    dot "$category" "$action"
  fi
}

# ── Pickers ───────────────────────────────────────────────────────────────────
_dot_pick_recipe() {
  ls "$DOTFILES/meta/recipes/" 2>/dev/null \
    | fzf --prompt="recipe> " --header="Select profile" --reverse
}

_dot_pick_ingredient() {
  ls "$DOTFILES/meta/ingredients/"*.yaml 2>/dev/null \
    | xargs -I{} basename {} .yaml \
    | fzf --prompt="ingredient> " --header="Select ingredient" --reverse
}

# ── Help ──────────────────────────────────────────────────────────────────────
_dot_help() {
  echo ""
  echo "\033[1mdot\033[0m — unified dotfiles CLI"
  echo ""
  echo "\033[1mUsage:\033[0m dot [command] [subcommand] [args...]"
  echo "       dot                    (interactive fzf menu)"
  echo ""

  local current_category=""
  local key description category action
  local -a toplevel_keys=()

  # First pass: grouped commands (category/action)
  for key in ${(ko)DOT_COMMANDS}; do
    category="${key%%/*}"
    action="${key#*/}"

    if [[ "$category" == "$action" ]]; then
      toplevel_keys+=("$key")
      continue
    fi

    description="${DOT_COMMANDS[$key]}"
    if [[ "$category" != "$current_category" ]]; then
      [[ -n "$current_category" ]] && echo ""
      current_category="$category"
      echo "  \033[1m$category\033[0m"
    fi
    printf "    \033[36m%-24s\033[0m %s\n" "$action" "$description"
  done

  # Second pass: top-level commands
  if (( ${#toplevel_keys} > 0 )); then
    echo ""
    for key in "${toplevel_keys[@]}"; do
      description="${DOT_COMMANDS[$key]}"
      printf "  \033[36m%-26s\033[0m %s\n" "$key" "$description"
    done
  fi

  echo ""
}

# ── Update Wizard ─────────────────────────────────────────────────────────────
_dot_update_wizard() {
  local all_yes=false
  [[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]] && all_yes=true

  echo "Starting update process..."
  echo ""

  local lazyvim_updated=false

  # 1. LazyVim
  if command_exists nvim; then
    if $all_yes || _dot_ask "Update LazyVim?"; then
      echo "Updating LazyVim..."
      if nvim --headless '+Lazy! update' +qa; then
        lazyvim_updated=true
        echo "LazyVim updated."
      else
        echo "LazyVim update failed (exit $?)." >&2
      fi
    else
      echo "LazyVim skipped."
    fi
  fi

  # 2. Homebrew
  if command_exists brew; then
    if $all_yes || _dot_ask "Update Homebrew packages?"; then
      echo "Updating Homebrew..."
      if ! brew update; then
        echo "brew update failed." >&2
      fi
      echo "Upgrading packages..."
      if ! brew upgrade; then
        echo "brew upgrade failed." >&2
      fi
      echo "Cleaning up..."
      brew cleanup -s
      echo "Homebrew done."
    else
      echo "Homebrew skipped."
    fi
  fi

  # 3. App Store (macOS only)
  if is_macos && command_exists mas; then
    if $all_yes || _dot_ask "Update App Store apps?"; then
      echo "Updating App Store..."
      if mas upgrade; then
        echo "App Store updated."
      else
        echo "App Store update failed (exit $?)." >&2
      fi
    else
      echo "App Store skipped."
    fi
  fi

  # 4. System update (macOS only)
  if is_macos; then
    if $all_yes || _dot_ask "Update macOS system?"; then
      echo "Updating macOS..."
      if softwareupdate -i -a; then
        echo "System updated."
      else
        echo "System update failed (exit $?)." >&2
      fi
    else
      echo "System update skipped."
    fi
  fi

  echo ""
  echo "Remember to update node/npm packages manually."
  if ! $lazyvim_updated; then
    echo "Consider updating Mason LSPs manually (:Mason in nvim)."
  fi
  echo "Update complete."
}

# ── Clean Home ────────────────────────────────────────────────────────────────
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
    echo "No stray ZSH files found in HOME."
    return
  fi

  echo "Found ZSH files in HOME:"
  echo "$zsh_items"
  echo ""

  if _dot_ask "Remove these files?"; then
    echo "$zsh_items" | while read -r item; do
      rm -rf "$item"
    done
    echo "Cleanup complete."
  else
    echo "Cleanup skipped."
  fi
}

# ── Helpers ───────────────────────────────────────────────────────────────────
_dot_ask() {
  local question="$1"
  echo -n "$question [y/N] "
  read -q
  local result=$?
  echo ""
  return $result
}

# ── Completion ────────────────────────────────────────────────────────────────
_dot() {
  local -a commands install_subcmds brew_subcmds shell_subcmds nvim_subcmds rb_subcmds

  commands=(
    'install:Install dotbot profiles or ingredients'
    'brew:Homebrew management'
    'shell:Shell configuration'
    'nvim:Neovim management'
    'rb:Remote Bridge'
    'update:Interactive update wizard'
    'edit:Open dotfiles in editor'
    'color-test:Terminal color test'
    'help:Show all commands'
  )

  install_subcmds=(
    'profile:Install a dotbot profile'
    'standalone:Install a standalone ingredient'
  )

  brew_subcmds=(
    'update:Update, upgrade & cleanup'
    'dump:Export to Brewfile'
  )

  shell_subcmds=(
    'reload:Reload ZSH configuration'
    'reset:Reset zinit and reload'
    'clean:Remove stray ZSH files from HOME'
  )

  nvim_subcmds=(
    'reset:Reset lazy.nvim packages'
  )

  rb_subcmds=(
    'start:Start service'
    'stop:Stop service'
    'restart:Restart service'
    'status:Show status'
    'logs:View logs'
  )

  case "$words[2]" in
    install)
      if (( CURRENT == 3 )); then
        _describe 'subcommand' install_subcmds
      elif (( CURRENT == 4 )); then
        case "$words[3]" in
          profile)
            local -a profiles
            profiles=(${(f)"$(ls "$DOTFILES/meta/recipes/" 2>/dev/null)"})
            _describe 'profile' profiles
            ;;
          standalone)
            local -a ingredients
            ingredients=(${(f)"$(ls "$DOTFILES/meta/ingredients/"*.yaml 2>/dev/null | xargs -I{} basename {} .yaml)"})
            _describe 'ingredient' ingredients
            ;;
        esac
      fi
      ;;
    brew)
      (( CURRENT == 3 )) && _describe 'subcommand' brew_subcmds
      ;;
    shell)
      (( CURRENT == 3 )) && _describe 'subcommand' shell_subcmds
      ;;
    nvim)
      (( CURRENT == 3 )) && _describe 'subcommand' nvim_subcmds
      ;;
    rb)
      (( CURRENT == 3 )) && _describe 'subcommand' rb_subcmds
      ;;
    update)
      if (( CURRENT == 3 )); then
        local -a update_opts
        update_opts=(
          '--yes:Skip all confirmation prompts'
          '-y:Skip all confirmation prompts'
        )
        _describe 'option' update_opts
      fi
      ;;
    *)
      (( CURRENT == 2 )) && _describe 'command' commands
      ;;
  esac
}

compdef _dot dot

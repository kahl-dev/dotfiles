#!/usr/bin/env zsh
# dot — unified dotfiles CLI v2.0.0
# Usage: dot [command] [subcommand] [args...]
# No args → fzf interactive menu

DOT_VERSION="2.0.0"

# Clear any conflicting alias
unalias dot 2>/dev/null

# Guard: $DOTFILES must be set
if [[ -z "$DOTFILES" ]]; then
  echo "dot: \$DOTFILES is not set" >&2
  return 1
fi

# ── NO_COLOR Support ─────────────────────────────────────────────────────────
if [[ -n "${NO_COLOR:-}" ]]; then
  _dot_bold="" _dot_cyan="" _dot_reset=""
else
  _dot_bold=$'\033[1m' _dot_cyan=$'\033[36m' _dot_reset=$'\033[0m'
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
  "mise/install"      "Install mise global tools"
  "mise/upgrade"      "Upgrade all mise tools to latest"
  "mise/outdated"     "Show outdated mise tools"
  "edit"              "Open dotfiles in editor"
  "color-test"        "Run terminal color test"
  "clean"             "Unified cache and temp cleanup"
  "status"            "Show dotfiles health dashboard"
  "sync"              "Pull latest dotfiles and apply"
  "doctor"            "Diagnose and fix common dotfiles issues"
  "help"              "Show all commands"
)

# ── Helpers ───────────────────────────────────────────────────────────────────
_dot_ask() {
  local question="$1"
  echo -n "$question [y/N] "
  read -q
  local result=$?
  echo ""
  return $result
}

_dot_subcmd_error() {
  local category="$1" subcommand="$2"
  shift 2
  if [[ -z "$subcommand" ]]; then
    echo "dot $category: missing subcommand" >&2
  else
    echo "dot $category: unknown subcommand '$subcommand'" >&2
  fi
  echo "Usage: dot $category [$*]" >&2
  return 1
}

_dot_validate_name() {
  local context="$1" name="$2"
  if [[ "$name" == */* || "$name" == *..* ]]; then
    echo "dot $context: invalid name '$name'" >&2
    return 1
  fi
}

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
    --version|-v)
      echo "dot $DOT_VERSION"
      ;;

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
          _dot_validate_name "install profile" "$name" || return 1
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
          _dot_validate_name "install standalone" "$name" || return 1
          if [[ ! -f "$DOTFILES/meta/ingredients/${name}.yaml" ]]; then
            echo "dot install standalone: '$name' not found in $DOTFILES/meta/ingredients/" >&2
            return 1
          fi
          echo "Installing ingredient: $name"
          "$DOTFILES/install-standalone" "$name"
          ;;
        *)
          _dot_subcmd_error "install" "$subcommand" "profile|standalone"
          ;;
      esac
      ;;

    brew)
      local subcommand="${1:-}"
      [[ -n "$subcommand" ]] && shift
      if ! command_exists brew; then
        echo "dot brew: brew is not installed" >&2
        return 1
      fi
      case "$subcommand" in
        update)
          echo "Updating Homebrew..."
          brew update && brew upgrade && brew cleanup -s
          ;;
        dump)
          if [[ -z "${HOMEBREW_BUNDLE_FILE_GLOBAL:-}" ]]; then
            echo "dot brew dump: \$HOMEBREW_BUNDLE_FILE_GLOBAL is not set" >&2
            return 1
          fi
          echo "Exporting to $HOMEBREW_BUNDLE_FILE_GLOBAL"
          brew bundle dump --force --describe --file="$HOMEBREW_BUNDLE_FILE_GLOBAL"
          ;;
        *)
          _dot_subcmd_error "brew" "$subcommand" "update|dump"
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
          _dot_clean home
          ;;
        *)
          _dot_subcmd_error "shell" "$subcommand" "reload|reset|clean"
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
        *)
          _dot_subcmd_error "nvim" "$subcommand" "reset"
          ;;
      esac
      ;;

    mise)
      local subcommand="${1:-}"
      [[ -n "$subcommand" ]] && shift
      if ! command_exists mise; then
        echo "dot mise: mise is not installed" >&2
        return 1
      fi
      case "$subcommand" in
        install)
          echo "Installing mise global tools..."
          mise install
          ;;
        upgrade)
          echo "Upgrading mise tools..."
          mise upgrade
          ;;
        outdated)
          mise outdated
          ;;
        *)
          _dot_subcmd_error "mise" "$subcommand" "install|upgrade|outdated"
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
        *)
          _dot_subcmd_error "rb" "$subcommand" "start|stop|restart|status|logs"
          ;;
      esac
      ;;

    clean)
      _dot_clean "$@"
      ;;

    status)
      _dot_status "$@"
      ;;

    sync)
      _dot_sync "$@"
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

    doctor)
      _dot_doctor "$@"
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
  echo "${_dot_bold}dot${_dot_reset} — unified dotfiles CLI v${DOT_VERSION}"
  echo ""
  echo "${_dot_bold}Usage:${_dot_reset} dot [command] [subcommand] [args...]"
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
      echo "  ${_dot_bold}$category${_dot_reset}"
    fi
    printf "    ${_dot_cyan}%-24s${_dot_reset} %s\n" "$action" "$description"
  done

  # Second pass: top-level commands
  if (( ${#toplevel_keys} > 0 )); then
    echo ""
    for key in "${toplevel_keys[@]}"; do
      description="${DOT_COMMANDS[$key]}"
      printf "  ${_dot_cyan}%-26s${_dot_reset} %s\n" "$key" "$description"
    done
  fi

  echo ""
}

# ── Completion ────────────────────────────────────────────────────────────────
_dot() {
  local -a commands install_subcmds brew_subcmds shell_subcmds nvim_subcmds mise_subcmds rb_subcmds

  commands=(
    'install:Install dotbot profiles or ingredients'
    'brew:Homebrew management'
    'shell:Shell configuration'
    'nvim:Neovim management'
    'mise:Mise global tools'
    'rb:Remote Bridge'
    'update:Interactive update wizard'
    'edit:Open dotfiles in editor'
    'color-test:Terminal color test'
    'clean:Unified cache and temp cleanup'
    'status:Show dotfiles health dashboard'
    'sync:Pull latest dotfiles and apply'
    'doctor:Diagnose and fix common issues'
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

  mise_subcmds=(
    'install:Install global tools'
    'upgrade:Upgrade all tools'
    'outdated:Show outdated tools'
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
    mise)
      (( CURRENT == 3 )) && _describe 'subcommand' mise_subcmds
      ;;
    rb)
      (( CURRENT == 3 )) && _describe 'subcommand' rb_subcmds
      ;;
    clean)
      if (( CURRENT == 3 )); then
        local -a clean_opts
        clean_opts=(
          'brew:Clean Homebrew cache'
          'uv:Clean uv cache'
          'docker:Clean Docker system'
          'nvim:Clean Neovim swap/shada/logs'
          'node:Prune pnpm store'
          'logs:Clean old logs'
          'caches:Clean misc caches'
          'claude:Clean old CLI versions'
          'home:Clean stray ZSH files'
          'all:Clean everything'
          '--dry-run:Show reclaimable space only'
          '--yes:Skip prompts'
        )
        _describe 'category' clean_opts
      fi
      ;;
    sync)
      if (( CURRENT == 3 )); then
        local -a sync_opts
        sync_opts=(
          '--update:Also run update wizard'
          '--dry-run:Show diff without applying'
        )
        _describe 'option' sync_opts
      fi
      ;;
    doctor)
      if (( CURRENT == 3 )); then
        local -a doctor_opts
        doctor_opts=(
          '--fix:Scan and offer to fix each issue'
        )
        _describe 'option' doctor_opts
      elif (( CURRENT == 4 )) && [[ "$words[3]" == "--fix" ]]; then
        local -a doctor_fix_opts
        doctor_fix_opts=(
          '--yes:Fix everything without prompting'
        )
        _describe 'option' doctor_fix_opts
      fi
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

# ── Source Extensions ────────────────────────────────────────────────────────
# Order matters: all extensions need _dot_ask defined above
source "$ZDOTDIR/config/update.zsh"
source "$ZDOTDIR/config/doctor.zsh"
source "$ZDOTDIR/config/clean.zsh"
source "$ZDOTDIR/config/status.zsh"
source "$ZDOTDIR/config/sync.zsh"

compdef _dot dot

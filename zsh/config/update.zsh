#!/usr/bin/env zsh
# 🔄 dot update — interactive update wizard
# Extracted from dot.zsh. Requires _dot_ask from dot.zsh.

# Timeout wrapper: use coreutils timeout/gtimeout if available, else run without
_dot_timeout() {
  local seconds="$1"
  shift
  if command -v timeout &>/dev/null; then
    timeout "$seconds" "$@"
  elif command -v gtimeout &>/dev/null; then
    gtimeout "$seconds" "$@"
  else
    # No timeout available — run directly (may hang)
    if [[ -z "${_dot_timeout_warned:-}" ]]; then
      echo "     (no timeout command — install coreutils for hang protection)" >&2
      _dot_timeout_warned=1
    fi
    "$@"
  fi
}

_dot_update_wizard() {
  local all_yes=false
  [[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]] && all_yes=true

  echo "Starting update process..."
  echo ""

  # Track status for summary
  typeset -A update_status

  # 1. Zinit (self + plugins)
  if (( $+commands[zinit] )) || (( $+functions[zinit] )); then
    if $all_yes || _dot_ask "Update zinit and plugins?"; then
      echo "Updating zinit..."
      if zinit self-update && zinit update --all; then
        update_status[zinit]="updated"
      else
        update_status[zinit]="failed"
      fi
    else
      update_status[zinit]="skipped"
    fi
  fi

  # 2. LazyVim
  if command_exists nvim; then
    if $all_yes || _dot_ask "Update LazyVim?"; then
      echo "Updating LazyVim..."
      if _dot_timeout 120 nvim --headless '+Lazy! update' +qa 2>/dev/null; then
        update_status[LazyVim]="updated"
      else
        update_status[LazyVim]="failed"
      fi
    else
      update_status[LazyVim]="skipped"
    fi
  fi

  # 3. Treesitter parsers
  if command_exists nvim; then
    if $all_yes || _dot_ask "Update Treesitter parsers?"; then
      echo "Updating Treesitter..."
      if _dot_timeout 120 nvim --headless '+TSUpdateSync' +qa 2>/dev/null; then
        update_status[Treesitter]="updated"
      else
        update_status[Treesitter]="failed"
      fi
    else
      update_status[Treesitter]="skipped"
    fi
  fi

  # 4. Mason LSPs
  if command_exists nvim; then
    if $all_yes || _dot_ask "Update Mason LSPs?"; then
      echo "Updating Mason..."
      if _dot_timeout 120 nvim --headless '+MasonUpdate' +qa 2>/dev/null; then
        update_status[Mason]="updated"
      else
        update_status[Mason]="failed"
      fi
    else
      update_status[Mason]="skipped"
    fi
  fi

  # 5. Homebrew
  if command_exists brew; then
    if $all_yes || _dot_ask "Update Homebrew packages?"; then
      echo "Updating Homebrew..."
      if ! brew update; then
        echo "brew update failed, skipping upgrade." >&2
        update_status[Homebrew]="failed"
      else
        echo "Upgrading packages..."
        if ! brew upgrade; then
          echo "brew upgrade failed." >&2
          update_status[Homebrew]="failed"
        else
          echo "Cleaning up..."
          brew cleanup -s
          update_status[Homebrew]="updated"
        fi
      fi
    else
      update_status[Homebrew]="skipped"
    fi
  fi

  # 6. Brew bundle dump (optional, after brew upgrade)
  if command_exists brew && [[ -n "${HOMEBREW_BUNDLE_FILE_GLOBAL:-}" ]]; then
    if $all_yes || _dot_ask "Export Brewfile?"; then
      echo "Exporting Brewfile..."
      if brew bundle dump --force --describe --file="$HOMEBREW_BUNDLE_FILE_GLOBAL"; then
        update_status[Brewfile]="updated"
      else
        update_status[Brewfile]="failed"
      fi
    else
      update_status[Brewfile]="skipped"
    fi
  fi

  # 7. App Store (macOS only)
  if is_macos && command_exists mas; then
    if $all_yes || _dot_ask "Update App Store apps?"; then
      echo "Updating App Store..."
      if mas upgrade; then
        update_status[AppStore]="updated"
      else
        update_status[AppStore]="failed"
      fi
    else
      update_status[AppStore]="skipped"
    fi
  fi

  # 8. Tmux plugins
  local tpm_update="$DOTFILES/tmux/plugins/tpm/bin/update_plugins"
  if [[ -x "$tpm_update" ]]; then
    if $all_yes || _dot_ask "Update tmux plugins?"; then
      echo "Updating tmux plugins..."
      if "$tpm_update" all; then
        update_status[tmux]="updated"
      else
        update_status[tmux]="failed"
      fi
    else
      update_status[tmux]="skipped"
    fi
  fi

  # 9. Mise tools
  if command_exists mise; then
    if $all_yes || _dot_ask "Upgrade mise tools?"; then
      echo "Upgrading mise tools..."
      if mise upgrade; then
        update_status[mise]="updated"
      else
        update_status[mise]="failed"
      fi
    else
      update_status[mise]="skipped"
    fi
  fi

  # Summary
  echo ""
  echo "Update complete:"
  local key status icon
  for key in zinit LazyVim Treesitter Mason Homebrew Brewfile AppStore tmux mise; do
    status="${update_status[$key]:-}"
    [[ -z "$status" ]] && continue
    case "$status" in
      updated) icon="✓" ;;
      failed)  icon="✗" ;;
      skipped) icon="-" ;;
      timeout) icon="⏱" ;;
      *)       icon="?" ;;
    esac
    printf "  %s %-14s %s\n" "$icon" "$key" "$status"
  done
  echo ""
}

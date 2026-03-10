#!/usr/bin/env zsh
# 🔄 dot update — interactive update wizard
# Extracted from dot.zsh. Requires _dot_ask from dot.zsh.
#
# Usage:
#   dot update              — interactive wizard (prompts for each tool)
#   dot update --yes        — all tools, no prompts
#   dot update brew         — single tool, with prompt
#   dot update --yes rtk    — single tool, no prompt

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
  local filter_tool=""

  # Parse arguments: flags and optional tool name
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes|-y) all_yes=true ;;
      --help|-h)
        echo "Usage: dot update [--yes|-y] [tool]"
        echo ""
        echo "Tools: zinit, lazyvim, treesitter, mason, brew, brewfile, tpm, mise, rtk, repos"
        echo ""
        echo "Options:"
        echo "  --yes, -y    Skip confirmation prompts"
        echo ""
        echo "Examples:"
        echo "  dot update            Interactive wizard"
        echo "  dot update --yes      All tools, no prompts"
        echo "  dot update brew       Single tool"
        echo "  dot update --yes rtk  Single tool, no prompt"
        return 0
        ;;
      *) filter_tool="${1:l}" ;;  # lowercase for matching
    esac
    shift
  done

  # Helper: should this tool run?
  _should_run() { [[ -z "$filter_tool" || "$filter_tool" == "$1" ]]; }

  if [[ -z "$filter_tool" ]]; then
    echo "Starting update process..."
    echo ""
  fi

  # Track status for summary
  typeset -A update_status

  # 1. Zinit (self + plugins)
  if _should_run "zinit"; then
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
  fi

  # 2. LazyVim
  if _should_run "lazyvim"; then
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
  fi

  # 3. Treesitter parsers
  if _should_run "treesitter"; then
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
  fi

  # 4. Mason LSPs
  if _should_run "mason"; then
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
  fi

  # 5. Homebrew
  if _should_run "brew"; then
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
            _dot_touch_update "brew-update"
            update_status[Homebrew]="updated"
          fi
        fi
      else
        update_status[Homebrew]="skipped"
      fi
    fi
  fi

  # 6. Brew bundle dump (optional, after brew upgrade)
  if _should_run "brewfile"; then
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
  fi

  # 7. Tmux plugins
  if _should_run "tpm"; then
    local tpm_update="$DOTFILES/tmux/plugins/tpm/bin/update_plugins"
    if [[ -x "$tpm_update" ]]; then
      if $all_yes || _dot_ask "Update tmux plugins?"; then
        echo "Updating tmux plugins..."
        if "$tpm_update" all; then
          _dot_touch_update "tpm-update"
          update_status[tmux]="updated"
        else
          update_status[tmux]="failed"
        fi
      else
        update_status[tmux]="skipped"
      fi
    fi
  fi

  # 8. Mise tools
  if _should_run "mise"; then
    if command_exists mise; then
      if $all_yes || _dot_ask "Upgrade mise tools?"; then
        echo "Upgrading mise tools..."
        if mise upgrade; then
          _dot_touch_update "mise-update"
          update_status[mise]="updated"
        else
          update_status[mise]="failed"
        fi
      else
        update_status[mise]="skipped"
      fi
    fi
  fi

  # 9. RTK (Rust Token Killer)
  if _should_run "rtk"; then
    if command -v rtk &>/dev/null; then
      if $all_yes || _dot_ask "Update RTK?"; then
        echo "Checking RTK version..."
        local rtk_current rtk_latest
        rtk_current="$(rtk --version 2>/dev/null | grep -o '[0-9]*\.[0-9]*\.[0-9]*' || echo 'unknown')"

        rtk_latest="$(curl -fsSL --connect-timeout 5 https://api.github.com/repos/rtk-ai/rtk/releases/latest 2>/dev/null \
          | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*"tag_name": *"//;s/"//;s/^v//')"

        if [[ -z "$rtk_latest" ]]; then
          echo "⚠️  Could not fetch latest RTK version (network error), skipping" >&2
          update_status[RTK]="failed"
        elif [[ "$rtk_current" == "$rtk_latest" ]]; then
          echo "✓ RTK already up to date ($rtk_current)"
          _dot_touch_update "rtk-update"
          update_status[RTK]="updated"
        else
          echo "📦 Updating RTK $rtk_current → $rtk_latest..."
          # Activate mise rust environment
          eval "$(mise env -s bash rust 2>/dev/null)" 2>/dev/null
          if ! command -v cargo &>/dev/null; then
            echo "⚠️  cargo not available (add rust to mise config), skipping RTK update" >&2
            update_status[RTK]="failed"
          elif _dot_timeout 120 cargo install --git https://github.com/rtk-ai/rtk --quiet 2>&1; then
            echo "✓ RTK updated to $(rtk --version 2>/dev/null | grep -o '[0-9]*\.[0-9]*\.[0-9]*')"
            echo "🔄 Updating hook..."
            rtk init -g --auto-patch 2>&1 || echo "⚠️  Hook update failed (non-blocking)" >&2
            _dot_touch_update "rtk-update"
            update_status[RTK]="updated"
          else
            echo "⚠️  RTK update failed (cargo build error)" >&2
            update_status[RTK]="failed"
          fi
        fi
      else
        update_status[RTK]="skipped"
      fi
    fi
  fi

  # 10. Repo sync
  if _should_run "repos"; then
    if (( ${#DOT_REPOS} > 0 )); then
      if $all_yes || _dot_ask "Sync registered repos?"; then
        echo "Syncing repos..."
        if _dot_repos "sync"; then
          update_status[repos]="updated"
        else
          update_status[repos]="failed"
        fi
      else
        update_status[repos]="skipped"
      fi
    fi
  fi

  # Summary
  echo ""
  echo "Update complete:"
  local key tool_status icon
  for key in zinit LazyVim Treesitter Mason Homebrew Brewfile tmux mise RTK repos; do
    tool_status="${update_status[$key]:-}"
    [[ -z "$tool_status" ]] && continue
    case "$tool_status" in
      updated) icon="✓" ;;
      failed)  icon="✗" ;;
      skipped) icon="-" ;;
      timeout) icon="⏱" ;;
      *)       icon="?" ;;
    esac
    printf "  %s %-14s %s\n" "$icon" "$key" "$tool_status"
  done
  echo ""
}

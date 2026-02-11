#!/usr/bin/env zsh
# 🔄 dot sync — pull latest dotfiles and apply

_dot_sync() {
  local with_update=false
  local dry_run=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --update) with_update=true; shift ;;
      --dry-run|-n) dry_run=true; shift ;;
      *) echo "dot sync: unknown option '$1'" >&2; return 1 ;;
    esac
  done

  if $dry_run; then
    echo "Fetching latest changes (dry run)..."
    git -C "$DOTFILES" fetch
    local diff_count
    diff_count=$(git -C "$DOTFILES" log HEAD..@{u} --oneline 2>/dev/null | wc -l | tr -d ' ')
    if (( diff_count == 0 )); then
      echo "Already up to date."
    else
      echo "$diff_count new commit(s):"
      git -C "$DOTFILES" log HEAD..@{u} --oneline
    fi
    return
  fi

  # Pull with autostash
  echo "Pulling latest dotfiles..."
  if ! git -C "$DOTFILES" pull --rebase --autostash; then
    echo "Pull failed. Resolve conflicts in $DOTFILES" >&2
    return 1
  fi

  # Detect profile (personal repo: non-Pi Linux = liadev workstation)
  local profile
  if is_macos; then
    profile="macos"
  elif is_raspberry_pi; then
    profile="pi"
  else
    profile="liadev"
  fi
  if [[ -f "$DOTFILES/meta/recipes/$profile" ]]; then
    echo "Re-running install profile: $profile"
    "$DOTFILES/install-profile" "$profile"
  fi

  # Chain update if requested
  if $with_update; then
    echo ""
    _dot_update_wizard --yes
    echo ""
    echo "Run 'exec zsh' to apply shell changes."
  else
    echo ""
    echo "Sync complete. Run 'exec zsh' to apply shell changes."
  fi
}

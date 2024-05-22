# -----------------------------------------------------------------------------
# This file is sourced for login shell sessions.
# Place your login-specific environment variables and commands here.
# It is sourced after ~/.zshenv but before ~/.zshrc.
# -----------------------------------------------------------------------------

source $DOTFILES/zsh/utils.zsh

if is_macos && path_exists "/opt/homebrew/bin/brew"; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  # FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

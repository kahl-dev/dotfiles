# -----------------------------------------------------------------------------
# This file is sourced for login shell sessions.
# Place your login-specific environment variables and commands here.
# It is sourced after ~/.zshenv but before ~/.zshrc.
# -----------------------------------------------------------------------------

source $DOTFILES/zsh/utils.zsh

if is_macos && path_exists "/opt/homebrew/bin/brew"; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  export PATH="$(brew --prefix)/opt/python/libexec/bin:${PATH}"
fi

if command_exists fnm; then
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
fi

FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

# if command_exists rbenv; then
#   eval "$(rbenv init - zsh)"
#   FPATH=~/.rbenv/completions:"$FPATH"
#   export PATH="$HOME/.rbenv/bin:$PATH"
# fi

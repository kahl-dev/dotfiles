if is_macos && path_exists "/opt/homebrew/bin/brew"; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

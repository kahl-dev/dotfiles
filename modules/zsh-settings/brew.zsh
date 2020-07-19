# linux only
if [ "$(uname 2> /dev/null)" = "Linux" ] && [ -d "$HOME/.linuxbrew" ]; then
  PATH="$HOME/.linuxbrew/bin:$PATH"
  MANPATH="$(brew --prefix)/share/man:$MANPATH"
  export INFOPATH="$(brew --prefix)/share/info:$INFOPATH"
  HOMEBREW_BUILD_FROM_SOURCE=1
fi


# https://docs.brew.sh/Shell-Completion
# Brew auto completion
if [ "$(uname 2> /dev/null)" = "Darwin" ]; then
  if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
  fi
fi

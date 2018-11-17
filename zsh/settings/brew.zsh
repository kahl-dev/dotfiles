# linux only
if [ "$(uname 2> /dev/null)" = "Linux" ] && [ -d "$HOME/.linuxbrew" ]; then

  PATH="$HOME/.linuxbrew/bin:$HOME/.linuxbrew/sbin:$PATH"
  export MANPATH="$(brew --prefix)/share/man:$MANPATH"
  export INFOPATH="$(brew --prefix)/share/info:$INFOPATH"
  HOMEBREW_BUILD_FROM_SOURCE=1

  #alias vim="${HOME}/.linuxbrew/bin/vim"
fi

export PATH="/usr/local/sbin:$PATH"

if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
fi

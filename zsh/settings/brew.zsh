# linux only
if [ "$(uname 2> /dev/null)" = "Linux" ] && [ -d "$HOME/.linuxbrew" ]; then

  PATH="$HOME/.linuxbrew/bin:$HOME/.linuxbrew/sbin:$PATH"
  export MANPATH="$(brew --prefix)/share/man:$MANPATH"
  export INFOPATH="$(brew --prefix)/share/info:$INFOPATH"
  HOMEBREW_BUILD_FROM_SOURCE=1

  if [ -f $HOME/bin/vim/src/vim ]; then
    alias vim="$HOME/bin/vim/src/vim"
  else
    alias vim="${HOME}/.linuxbrew/bin/vim"
  fi
fi

export PATH="/usr/local/sbin:$PATH"

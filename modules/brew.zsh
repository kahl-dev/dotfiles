# linux only
if [ "$(uname 2> /dev/null)" = "Linux" ]; then
  if [ -d "$HOME/.linuxbrew" ]; then
    PATH="$HOME/.linuxbrew/bin:$PATH"
    MANPATH="$(brew --prefix)/share/man:$MANPATH"
    export INFOPATH="$(brew --prefix)/share/info:$INFOPATH"
    HOMEBREW_BUILD_FROM_SOURCE=1
  else
    if ! $(which brew > /dev/null); then
      . "$DOTFILES/sh/linuxbrew.sh";
      brew bundle -v --no-upgrade --file "$DOTFILES/brew/Basebrew"
    fi
  fi
fi


# https://docs.brew.sh/Shell-Completion
# Brew auto completion
if [ "$(uname 2> /dev/null)" = "Darwin" ]; then
  if ! $(which brew > /dev/null); then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)";
    brew bundle -v --no-upgrade --file "$DOTFILES/brew/Basebrew"
    brew bundle -v --no-upgrade --file "$DOTFILES/brew/Osxbrew"
  fi
fi

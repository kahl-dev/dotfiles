# linux only
if [ "$(uname 2> /dev/null)" = "Linux" ]; then
  ## Setup linux brew
  export LINUXBREWHOME=$HOME/.linuxbrew
  export PATH=$LINUXBREWHOME/bin:$LINUXBREWHOME/sbin:$PATH
  export MANPATH=$LINUXBREWHOME/share/man:$MANPATH
  export PKG_CONFIG_PATH=$LINUXBREWHOME/lib64/pkgconfig:$LINUXBREWHOME/lib/pkgconfig:$PKG_CONFIG_PATH
  export LD_LIBRARY_PATH=$LINUXBREWHOME/lib64:$LINUXBREWHOME/lib:$LD_LIBRARY_PATH
  HOMEBREW_BUILD_FROM_SOURCE=1

  if ! $(which brew > /dev/null); then
    . "$DOTFILES/sh/linuxbrew.sh";
    brew bundle -v --no-upgrade --file "$DOTFILES/brew/Basebrew"

    pip3 install pynvim
  fi
fi


# https://docs.brew.sh/Shell-Completion
# Brew auto completion
if [ "$(uname 2> /dev/null)" = "Darwin" ]; then
  if ! $(which brew > /dev/null); then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)";
    brew bundle -v --no-upgrade --file "$DOTFILES/brew/Basebrew"
    brew bundle -v --no-upgrade --file "$DOTFILES/brew/Osxbrew"

    pip3 install pynvim
  fi
fi

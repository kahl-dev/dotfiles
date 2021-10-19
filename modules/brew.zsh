# linux only
if [ $IS_RASPBERRY = false ]; then
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

      # Setup terminfo for alacritty
      # Blog: https://medium.com/@pezcoder/how-i-migrated-from-iterm-to-alacritty-c50a04705f95#b24e
      git clone https://github.com/alacritty/alacritty.git
      cd alacritty
      sudo tic -xe alacritty,alacritty-direct extra/alacritty.info
      cd ..
      rm -rf alacritty


      export PATH="$(brew --prefix)/opt/python3@/bin:$PATH"
      export LDFLAGS="-L$(brew --prefix)/opt/python3@/lib"
      export PKG_CONFIG_PATH="$(brew --prefix)/opt/python3@/lib/pkgconfig"
      pip3 install pynvim
    fi

    export PATH="$(brew --prefix)/opt/python3@/bin:$PATH"
    export LDFLAGS="-L$(brew --prefix)/opt/python3@/lib"
    export PKG_CONFIG_PATH="$(brew --prefix)/opt/python3@/lib/pkgconfig"

  fi
fi

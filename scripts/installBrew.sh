#!/bin/bash

source ./scripts/config.sh
source ./scripts/functions.sh

# brew bundle install --file $DOTFI$DOTFILES/brew/Basebrew
if _is_linux; then
  LINUXBREWHOME=$HOME/.linuxbrew

  if ! _exec_exists brew; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    brew bundle -v --no-upgrade --file "$DOTFILES/brew/Basebrew"
    pip3 install pynvim
  fi

fi

if _is_osx; then
  if ! _exec_exists brew; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if ! _exec_exists brew; then
      brew bundle -v --no-upgrade --file "$DOTFILES/brew/Basebrew"
      brew bundle -v --no-upgrade --file "$DOTFILES/brew/Osxbrew"
      pip3 install pynvim
    fi
  fi

  mkdir -p $HOME/.config/alacritty
  _symlink $DOTFILES/config/alacritty.yml $HOME/.config/alacritty/alacritty.yml


  if _exec_exists brew && _exec_exists clipper; then
    _symlink $DOTFILES/config/clipper.json $HOME/.clipper.json
    brew services start clipper
  fi
fi

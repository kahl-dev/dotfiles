#!/bin/bash

source ./scripts/config.sh
source ./scripts/functions.sh

# brew bundle install --file $DOTFI$DOTFILES/brew/Basebrew
if _is_linux; then
  LINUXBREWHOME=$HOME/.linuxbrew

  if ! _exec_exists brew; then
    git clone https://github.com/Homebrew/brew $LINUXBREWHOME/Homebrew
    mkdir $LINUXBREWHOME/bin
    ln -s $LINUXBREWHOME/Homebrew/bin/brew $LINUXBREWHOME/bin
    eval $($LINUXBREWHOME/bin/brew shellenv)
    source $ZDOTDIR/.zshrc

    brew bundle -v --no-upgrade --file "$DOTFILES/brew/Basebrew"
    pip3 install pynvim
  fi

fi

if _is_osx; then
  if ! _exec_exists brew; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)";
    source $ZDOTDIR/.zshrc

    brew bundle -v --no-upgrade --file "$DOTFILES/brew/Basebrew"
    brew bundle -v --no-upgrade --file "$DOTFILES/brew/Osxbrew"
    pip3 install pynvim

    # Setup terminfo for alacritty
    # Blog: https://medium.com/@pezcoder/how-i-migrated-from-iterm-to-alacritty-c50a04705f95#b24e
    # git clone https://github.com/alacritty/alacritty.git
    # cd alacritty
    # sudo tic -xe alacritty,alacritty-direct extra/alacritty.info
    # cd ..
    # rm -rf alacritty
  fi

  _symlink $DOTFILES/config/alacritty.yml $HOME/.config/alacritty/alacritty.yml


  if _exec_exists brew; then
    _symlink $DOTFILES/config/clipper.json $HOME/.clipper.json
    brew services start clipper
  fi
fi

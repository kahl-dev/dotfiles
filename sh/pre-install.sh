#!/usr/bin/env bash

# install and update homebrew/cask/linuxbrew
echo Pre install brew/linuxbrew, nvm and osx settings [Enter: y/n]
read var
if [ ! "$var" = "y" ]; then
  exit
fi

# osx only
if [ "$(uname)" = "Darwin" ]; then

  # install brew
  if ! (brew --version > /dev/null); then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  else
    brew update
    brew upgrade
  fi

  # install cask
  brew tap caskroom/cask
  brew tap caskroom/fonts

# linux only
elif [ "$(uname)" = "Linux" ]; then

  # install linuxbrew
  if ! (brew --version > /dev/null); then
    git clone https://github.com/Linuxbrew/brew.git ~/.linuxbrew
  else
    brew update
    brew upgrade
  fi

fi

source ~/.zshrc
nvm install node

sh $DOTFILES/sh/osx.sh

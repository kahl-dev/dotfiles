#!/bin/sh

# Execute if not linux
if [ ! "$(uname)" = "Linux" ]; then
  exit
fi

echo Handle Linux things? y/n
read var
if [ $var = "y" ]; then

  if brew ls --versions myformula > /dev/null; then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"
  else
    brew update
    brew upgrade
  fi

  # Install packages

  brew install xdg-utils
  brew install curl
  brew install nodejs-legacy

  # Dependency for YouCompleteMe
  brew install cmake

  # Ag/Ack the better grep
  brew install the_silver_searcher

  # Nice cd fuzzy search and index (Dependency for zsh plugin)
  # https://github.com/b4b4r07/enhancd
  brew install fzy

fi

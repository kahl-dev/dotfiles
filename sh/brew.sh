#!/bin/sh

# Execute if not osx
if [ ! "$(uname)" = "Darwin" ]; then
  exit
fi

echo Install Brew and Cask? y/n
read var
if [ $var = "y" ]; then

  # Install or update brew
  which -s brew
  if [[ $? != 0 ]] ; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  else
    brew update
    brew upgrade
  fi

  # Install packages

  brew install wget
  brew install macvim

  # Ag/Ack the better grep
  brew install the_silver_searcher

  # Nice cd fuzzy search and index (Dependency for zsh plugin)
  # https://github.com/b4b4r07/enhancd
  brew install fzy

  # Bugfix vim+tmux clipboard
  brew install reattach-to-user-namespace

  # Cask
  brew tap caskroom/cask
  brew install brew-cask
  brew cask install slack

fi

if brew info brew-cask | grep "brew-cask" >/dev/null 2>&1 ; then
  echo FOO
else
  echo BAR 
fi

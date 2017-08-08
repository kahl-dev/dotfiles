#!/bin/sh

# Execute if not osx
if [ ! "$(uname)" = "Darwin" ]; then
  exit
fi

echo Install Brew and Cask? y/n
read var
if [ $var = "y" ]; then

  # Install or update brew
  if ! (brew --version > /dev/null); then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  else
    brew update
    brew upgrade
  fi

  # Install packages
  for pkg in z git node wget vim macvim tmux the_silver_searcher fzy reattach-to-user-namespace mongodb sshfs; do
    if ! (brew list -1 | grep -q "^${pkg}\$"); then
        brew install $pkg
    fi
  done

  # Cask
  if ! (brew cask --version > /dev/null); then
    brew tap caskroom/cask
    brew install brew-cask
  fi

  # Install cask packages
  for pkg in slack mongodb-compass osxfuse hyper; do
    if ! (brew cask list -1 | grep -q "^${pkg}\$"); then
        brew cask install $pkg
    fi
  done

  brew cleanup

fi


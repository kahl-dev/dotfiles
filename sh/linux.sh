#!/bin/sh

# Execute if not linux
if [ ! "$(uname)" = "Linux" ]; then
  exit
fi

echo Handle Linux things? y/n
read var
if [ $var = "y" ]; then

  if ! (brew --version > /dev/null); then
    git clone https://github.com/Linuxbrew/brew.git ~/.linuxbrew
  else
    brew update
    brew upgrade
  fi

  # Install packages
  for pkg in z git vim tmux gcc cmake the_silver_searcher fzy; do
    if ! (brew list -1 | grep -q "^${pkg}\$"); then
        brew install $pkg
    fi
  done
fi

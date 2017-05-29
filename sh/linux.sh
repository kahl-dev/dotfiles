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
  for pkg in git npm vim tmux cmake the_silver_searcher fzy; do
    if ! (brew list -1 | grep -q "^${pkg}\$"); then
        brew install $pkg
    fi
  done
fi

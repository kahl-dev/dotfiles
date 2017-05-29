#!/bin/sh

# Execute if not linux
if [ ! "$(uname)" = "Linux" ]; then
  exit
fi

echo Handle Linux things? y/n
read var
if [ $var = "y" ]; then

  # {{{
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"

  brew install xdg-utils
  brew install curl
  brew install nodejs-legacy
  brew install cmake
  # }}}

fi

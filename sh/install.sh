#!/bin/sh

#
# Check if iterm2 scripts are installed
#
if [ ! -d ~/.iterm2 ] || [ ! -f ~/.iterm2_shell_integration.zsh ]; then
  curl -L https://iterm2.com/misc/install_shell_integration.sh | bash
fi

if [ "$(uname)" = "Darwin" ]; then
  # Do something under Mac OS X platform

  # Remove obsolete dashboard from os x
  if [ "$(defaults read com.apple.dashboard mcx-disabled)" == 0 ] ; then
    defaults write com.apple.dashboard mcx-disabled -boolean YES && killall Dock
  fi

  #
  # Check if Homebrew is installed
  #
  which -s brew
  if [[ $? != 0 ]] ; then
    # Install Homebrew
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew install wget
    brew install the_silver_searcher
    brew install ctags

    # Bugfix vim+tmux clipboard
    brew install reattach-to-user-namespace
  else
    brew update
  fi

  #
  # Ruby gems
  #
  #sudo gem install cmake

  # Do something under not OS X
  else
    echo "Do somthing"
fi


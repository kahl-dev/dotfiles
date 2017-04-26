#!/bin/sh

#
# Check if iterm2 scripts are installed
#
if [ ! -d "~/.iterm2" ]; then
  curl -L https://iterm2.com/misc/install_shell_integration_and_utilities.sh | bash
fi

#
# Install and update vim vundle plugins
#
vim -c VundleInstall -c quitall
vim -c VundleUpdate -c quitall

if [ "$(uname)" == "Darwin" ] ; then
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


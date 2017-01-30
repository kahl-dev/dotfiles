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

#
# Check if Homebrew is installed
#
which -s brew
if [[ $? != 0 ]] ; then
  # Install Homebrew
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  brew install wget
  brew install the_silver_searcher
  brew install cmake
else
  brew update
fi

#
# Ruby gems
#
sudo gem install cmake

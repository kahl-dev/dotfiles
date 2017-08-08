#!/bin/sh

# Execute if not osx
if [ ! "$(uname)" = "Darwin" ]; then
  exit
fi

echo Configure OSX? y/n
read var
if [ $var = "y" ]; then

  # {{{
  # http://snazzylabs.com/article/5-killer-macos-tricks-hidden-in-terminal/
  # Show Full File Path in Finder
  defaults write com.apple.finder _FXShowPosixPathInTitle -bool YES

  # Make Hidden Apps “Hidden” in Dock
  defaults write com.apple.Dock showhidden -bool TRUE

  # Eliminate the Dock Reveal Delay
  defaults write com.apple.dock autohide-time-modifier -float 0.12;

  # Remove obsolete dashboard from os x
  defaults write com.apple.dashboard mcx-disabled -boolean YES && killall Dock

  killall Finder
  killall Dock

  # }}}

  ./fonts/install.sh

fi

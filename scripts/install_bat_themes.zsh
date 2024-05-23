#!/usr/bin/env zsh

# https://github.com/catppuccin/bat

source $DOTFILES/zsh/utils.zsh

echo "\n<<< Starting Installing Bat themes >>>\n"

BAT_THEME="$(bat --config-dir)/themes/"
if ! path_exists $BAT_THEME; then
  echo "Installing bat catppuccin themes..."
  mkdir -p ~/.tmp/
  git clone https://github.com/catppuccin/bat.git ~/.tmp/catppuccino-bat
  mkdir -p $BAT_THEME
  cp ~/.tmp/catppuccino-bat/themes/*.tmTheme $BAT_THEME
  bat cache --build
  rm -Rf ~/.tmp/catppuccino-bat
fi

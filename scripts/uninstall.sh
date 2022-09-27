#!/bin/bash

source ./scripts/config.sh
source ./scripts/functions.sh

CREATED_SYMLINKS=(
  # General symlinks
  "$HOME/.zshenv"
  "$HOME/.config/zsh"
  "$HOME/.gitconfig"
  "$HOME/.gitignore_global"
  "$HOME/.gittemplate"
  "$HOME/.prettierrc.js"
  "$HOME/.tern-config"
  "$HOME/.eslintrc.js"
  "$HOME/.tmux"
  "$HOME/.tmux.conf"
  "$HOME/.agignore"
  "$HOME/.ssh/rc"
  "$HOME/.config/nvim"

  # OSX specific
  "$HOME/.config/alacritty/alacritty.yml"
  "$HOME/.clipper.json"
  "$HOME/.ssh/config"

  # Old ones
  "$HOME/.asdfrc"
  "$HOME/.base16_theme"
)

for file in "${CREATED_SYMLINKS[@]}"; do
  if [ -L $file ]; then
    printf "${COLOR_CYAN}Remove Symlink $file${COLOR_OFF}\n"
    rm $file
  else
    printf "${COLOR_YELLOW}Can not find $file${COLOR_OFF}\n"
  fi
done

rm -Rf ~/.ssh/config.d

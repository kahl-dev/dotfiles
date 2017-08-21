#!/usr/bin/env bash

echo Handle homebrew/cask/linuxbrew [Enter: y/n]
read brew
if [ "$brew" = "y" ]; then
  sh $DOTFILES/sh/brew.sh
fi

echo Handle node packages [Enter: y/n]
read npm
if [ "$npm" = "y" ]; then
  sh $DOTFILES/sh/npm.sh
fi

echo Handle tmux [Enter: y/n]
read tmux
if [ "$tmux" = "y" ]; then
  ~/.tmux/plugins/tpm/bin/install_plugins
  ~/.tmux/plugins/tpm/bin/update_plugins all
  ~/.tmux/plugins/tpm/bin/clean_plugins
fi

echo Handle vim [Enter: y/n]
read vim
if [ "$vim" = "y" ]; then
  vim +PlugInstall! +PlugUpdate! +PlugUpgrade! +PlugClean! +qa
fi

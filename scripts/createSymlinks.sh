#!/bin/bash

source ./scripts/config.sh
source ./scripts/functions.sh

_symlink $DOTFILES/zsh/.zshenv $HOME/.zshenv
_symlink $DOTFILES/zsh $HOME/.config/zsh

_symlink $DOTFILES/git/gitconfig $HOME/.gitconfig
_symlink $DOTFILES/git/gitignore_global $HOME/.gitignore_global
_symlink $DOTFILES/git/template ~/.gittemplate

_symlink $DOTFILES/config/prettierrc.js $HOME/.prettierrc.js

_symlink $DOTFILES/config/tern-config.json $HOME/.tern-config

_symlink $DOTFILES/config/eslintrc.js $HOME/.eslintrc.js

_symlink $DOTFILES/tmux $HOME/.tmux
_symlink $DOTFILES/tmux/tmux.conf $HOME/.tmux.conf

_symlink $DOTFILES/config/agignore $HOME/.agignore

_symlink $DOTFILES/config/rc $HOME/.ssh/rc

if _exec_exists nvim; then
  if [ ! -d "$HOME/.config/nvim" ]; then
    _symlink $DOTFILES/nvim $HOME/.config/nvim
  fi
fi

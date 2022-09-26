#!/bin/bash

source ./scripts/config.sh
source ./scripts/functions.sh

_symlink $DOTFILES/zsh/.zshenv $HOME/.zshenv
_symlink $DOTFILES/zsh $HOME/.config/zsh

_symlink $DOTFILES/git/gitconfig $HOME/.gitconfig
_symlink $DOTFILES/git/gitignore_global $HOME/.gitignore_global
_symlink $DOTFILES/git/template ~/.gittemplate

_symlink $DOTFILES/ee/prettierrc.js $HOME/.prettierrc.js

_symlink $DOTFILES/ee/tern-config.json $HOME/.tern-config

_symlink $DOTFILES/ee/eslintrc.js $HOME/.eslintrc.js

_symlink $DOTFILES/tmux $HOME/.tmux
_symlink $DOTFILES/tmux/tmux.conf $HOME/.tmux.conf

_symlink $DOTFILES/ee/agignore $HOME/.agignore

_symlink $DOTFILES/ssh/rc $HOME/.ssh/rc
mkdir -p ~/.ssh/config.d

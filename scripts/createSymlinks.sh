#!/bin/bash

source ./scripts/config.sh
source ./scripts/functions.sh

paths=(
	"$DOTFILES/zsh/.zshenv:$HOME/.zshenv"
	"$HOME/.config:"
	"$DOTFILES/zsh:$HOME/.config/zsh"
	"$DOTFILES/git/gitconfig:$HOME/.gitconfig"
	"$DOTFILES/git/gitignore_global:$HOME/.gitignore_global"
	"$DOTFILES/git/template:$HOME/.gittemplate"
	"$DOTFILES/config/prettierrc.js:$HOME/.prettierrc.js"
	"$DOTFILES/config/tern-config.json:$HOME/.tern-config"
	"$DOTFILES/config/eslintrc.js:$HOME/.eslintrc.js"
	"$DOTFILES/tmux:$HOME/.tmux"
	"$DOTFILES/tmux/tmux.conf:$HOME/.tmux.conf"
	"$DOTFILES/config/agignore:$HOME/.agignore"
	"$DOTFILES/config/rc:$HOME/.ssh/rc"
)

for path in "${paths[@]}"; do
	source=$(echo $path | cut -d: -f1)
	destination=$(echo $path | cut -d: -f2)
	if [ -z "$destination" ]; then
		_createPath $source
	else
		_symlink $source $destination
	fi
done

if _exec_exists nvim; then
	if ! _is_path_exists $HOME/.config/nvim; then
		_symlink $DOTFILES/nvim $HOME/.config/nvim
	fi
fi

if _exec_exists glow; then
	if ! _is_path_exists $HOME/.config/glow; then
		mkdir -p $HOME/.config/glow
	fi

	_symlink $DOTFILES/.config/glow.yml $HOME/.config/glow/glow.yml
fi

if _is_osx; then
	_copyfile $DOTFILES/config/com.kahl_dev.nc_listener.plist $HOME/Library/LaunchAgents/com.kahl_dev.nc_listener.plist
	_copyfile $DOTFILES/config/finicky.js $HOME/.finicky.js

	_symlink $DOTFILES/config/ssh-config $HOME/.ssh/config
	mkdir -p ~/.ssh/config.d

	mkdir -p $HOME/.config/alacritty
	_symlink $DOTFILES/config/alacritty.yml $HOME/.config/alacritty/alacritty.yml

	mkdir -p $HOME/.config/wezterm
	_symlink $DOTFILES/config/wezterm.lua $HOME/.config/wezterm/wezterm.lua
fi

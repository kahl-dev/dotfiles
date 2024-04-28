#!/bin/bash

source $DOTFILES/scripts/config.sh
source $DOTFILES/scripts/functions.sh

paths=(
	"$DOTFILES/zsh/.zshenv:$HOME/.zshenv"
	"$HOME/.config:"
	"$DOTFILES/zsh:$HOME/.config/zsh"
	"$DOTFILES/git/gitconfig:$HOME/.gitconfig"
	"$DOTFILES/git/gitignore_global:$HOME/.gitignore_global"
	"$DOTFILES/git/template:$HOME/.gittemplate"
	"$DOTFILES/config/prettierrc.js:$HOME/.prettierrc.js"
	"$DOTFILES/config/tern-config.json:$HOME/.tern-config"
	"$DOTFILES/tmux:$HOME/.tmux"
	"$DOTFILES/tmux/tmux.conf:$HOME/.tmux.conf"
	"$DOTFILES/config/agignore:$HOME/.agignore"
	"$DOTFILES/config/rc:$HOME/.ssh/rc"
	"$DOTFILES/config/lazygit.yml:$HOME/.config/lazygit/config.yml"
	"$DOTFILES/config/gh-copilot/config.yml:$HOME/.config/gh-copilot/config.yml"
)

for path in "${paths[@]}"; do
	IFS=':' read -r source destination <<<"$path"

	# Check if destination path is provided.
	if [ -z "$destination" ]; then
		# Assume _createPath is a function intended for creating directories.
		_createPath "$source"
	else
		# Check if the destination exists and is not a symlink.
		if [ -e "$destination" ] && [ ! -L "$destination" ]; then
			# Backup the existing file or directory.
			mv "$destination" "$destination.bak"
			printf "${COLOR_GREEN}Backed up $destination to $destination.bak${COLOR_OFF}\n"
		fi

		# Use the custom symlink function.
		_symlink "$source" "$destination"
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
	_copyfile $DOTFILES/config/com.kahl_dev.add_ssh.plist $HOME/Library/LaunchAgents/com.kahl_dev.add_ssh.plist
	_copyfile $DOTFILES/config/finicky.js $HOME/.finicky.js

	_symlink $DOTFILES/config/ssh-config $HOME/.ssh/config
	mkdir -p ~/.ssh/config.d

	mkdir -p $HOME/.config/alacritty
	_symlink $DOTFILES/config/alacritty.yml $HOME/.config/alacritty/alacritty.yml

	mkdir -p $HOME/.config/wezterm
	_symlink $DOTFILES/config/wezterm.lua $HOME/.config/wezterm/wezterm.lua
	_symlink $HOME/Library/Mobile\ Documents/com~apple~CloudDocs/ $HOME/icloud
fi

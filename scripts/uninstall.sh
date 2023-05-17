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
	"$HOME/.config/starship.toml"

	# OSX specific
	$HOME/.config/alacritty/alacritty.yml
	$HOME/.ssh/config
	$HOME/.finicky.js
	$HOME/Library/LaunchAgents/open.plist

	# Old ones
	"$HOME/.asdfrc"
	"$HOME/.base16_theme"
)

for file in "${CREATED_SYMLINKS[@]}"; do
	_removeSymlinkOrFile $file
done

rm -Rf ~/.ssh/config.d

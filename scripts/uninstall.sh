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
	"$HOME/.tmux"
	"$HOME/.tmux.conf"
	"$HOME/.ssh/rc"
	"$HOME/.config/nvim"
	"$HOME/.config/starship.toml"

	# OSX specific
	$HOME/.ssh/config
)

for file in "${CREATED_SYMLINKS[@]}"; do
	_removeSymlinkOrFile $file
done

rm -Rf ~/.ssh/config.d

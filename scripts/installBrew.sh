#!/bin/bash

source ./scripts/config.sh
source ./scripts/functions.sh

# brew bundle install --file $DOTFI$DOTFILES/brew/Basebrew
if _is_linux; then
	LINUXBREWHOME=$HOME/.linuxbrew

	if ! _exec_exists brew; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

		brew bundle -v --no-upgrade --file "$DOTFILES/brew/Basebrew"
		pip3 install pynvim
	fi

fi

if _is_osx; then
	if ! _exec_exists brew; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		if _is_path_exists "/opt/homebrew/bin/brew"; then
			eval "$(/opt/homebrew/bin/brew shellenv)"
		fi

		brew bundle -v --no-upgrade --file "$DOTFILES/brew/Basebrew"
		brew bundle -v --no-upgrade --file "$DOTFILES/brew/Osxbrew"
		pip3 install pynvim
	fi

fi

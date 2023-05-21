#!/bin/bash

source ./scripts/config.sh
source ./scripts/functions.sh

read -p "Do you want to update LazyVim? (y/n) " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
	printf "${COLOR_CYAN}Update LazyVim${COLOR_OFF}\n"
	nvim --headless '+Lazy! sync' +qa
fi

read -p "Do you want to update Homebrew packages? (y/n) " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
	printf "${COLOR_CYAN}Update Homebrew packages${COLOR_OFF}\n"
	brew update
	brew upgrade
	brew cleanup -s
	#now diagnotic
	brew doctor
	brew missing
fi

read -p "Do you want to update App Store packages with mas? (y/n) " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
	printf "${COLOR_CYAN}Update App Store packages with mas${COLOR_OFF}\n"
	mas upgrade
fi

read -p "Do you want to update the System? (y/n) " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
	printf "${COLOR_CYAN}Update System${COLOR_OFF}\n"
	softwareupdate -i -a
fi

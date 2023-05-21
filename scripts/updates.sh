#!/bin/bash

source ./scripts/config.sh
source ./scripts/functions.sh

all_yes=0

if [[ $1 == '--yes' ]] || [[ $1 == '-y' ]]; then
	all_yes=1
fi

if [[ $all_yes == 1 ]] || (read -p "Do you want to update LazyVim? (y/n) " response && [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]); then
	printf "${COLOR_CYAN}Update LazyVim${COLOR_OFF}\n"
	nvim --headless '+Lazy! sync' +qa
fi

if [[ $all_yes == 1 ]] || (read -p "Do you want to update Homebrew packages? (y/n) " response && [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]); then
	printf "${COLOR_CYAN}Update Homebrew packages${COLOR_OFF}\n"
	brew update
	brew upgrade
	brew cleanup -s
	#now diagnotic
	brew doctor
	brew missing
fi

if [[ $all_yes == 1 ]] || (read -p "Do you want to update App Store packages with mas? (y/n) " response && [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]); then
	printf "${COLOR_CYAN}Update App Store packages with mas${COLOR_OFF}\n"
	mas upgrade
fi

if [[ $all_yes == 1 ]] || (read -p "Do you want to update the System? (y/n) " response && [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]); then
	printf "${COLOR_CYAN}Update System${COLOR_OFF}\n"
	softwareupdate -i -a
fi

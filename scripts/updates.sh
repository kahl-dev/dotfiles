#!/bin/bash

source ./scripts/config.sh
source ./scripts/functions.sh

# https://www.chriswrites.com/update-apps-and-macos-without-ever-launching-the-app-store/

printf "${COLOR_CYAN}Update Homebrew packages${COLOR_OFF}\n"
brew update
brew upgrade
brew cleanup -s
#now diagnotic
brew doctor
brew missing

printf "${COLOR_CYAN}Update App Store packages with mas${COLOR_OFF}\n"
mas upgrade

printf "${COLOR_CYAN}Update System${COLOR_OFF}\n"
softwareupdate -i -a

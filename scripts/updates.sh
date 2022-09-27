#!/bin/bash
brew update
brew upgrade
brew cleanup -s
#now diagnotic
brew doctor
brew missing

#!/bin/bash

source ./scripts/config.sh
source ./scripts/functions.sh

if _is_osx; then
  _symlink $DOTFILES/config/ssh-config $HOME/.ssh/config
  mkdir -p ~/.ssh/config.d
fi

#!/bin/bash

source ./scripts/config.sh
source ./scripts/functions.sh

if _exec_exists brew; then
  brew install starship
else
  # curl -sS https://starship.rs/install.sh | sh --bin-dir $HOME/.local/bin
  curl -sS https://starship.rs/install.sh | sh
fi

_symlink $DOTFILES/config/starship.toml $HOME/.config/starship.toml

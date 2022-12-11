#!/bin/bash

source ./scripts/config.sh
source ./scripts/functions.sh

curl -sS https://starship.rs/install.sh | sh

_symlink $DOTFILES/config/starship.toml $HOME/.config/starship.toml

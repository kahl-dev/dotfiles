#!/bin/bash

source ./scripts/config.sh

_symlink() {
  TYPE='Create'
  if [ -L $2 ]; then
    rm $2
    TYPE='Overwrite'
  fi
  printf "${COLOR_CYAN}$TYPE symlink $1 -> $2${COLOR_OFF}\n"
  ln -s $1 $2
}

_exec_exists() {
  command -v "$1" >/dev/null 2>&1
}

_is_raspberry() {
  _exec_exists raspi-config
}

_is_osx() {
  [[ $(uname -s) =~ "Darwin" ]] && return 0 || return 1
}

_is_linux() {
  [[ $(uname -s) =~ "Linux" ]] && return 0 || return 1
}

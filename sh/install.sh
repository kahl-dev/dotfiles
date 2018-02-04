#!/usr/bin/env bash

echo Handle homebrew/cask/linuxbrew and app store [Enter: y/n]
read brew
if [ "$brew" = "y" ]; then
  sh $DOTFILES/sh/brew.sh
fi

echo Handle node packages [Enter: y/n]
read npm
if [ "$npm" = "y" ]; then
  sh $DOTFILES/sh/npm.sh
fi

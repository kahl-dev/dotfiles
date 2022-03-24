#!/bin/bash
cd ~
rm -Rf .cache .config .dotfiles .fzf .fzf.zsh .npm .yarn .yarnrc
find -L $DIR -maxdepth 1 -type l -delete


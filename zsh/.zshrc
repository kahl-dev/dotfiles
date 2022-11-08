#!/bin/bash

DOTFILES="$HOME/.dotfiles"

source $DOTFILES/scripts/config.sh
source $DOTFILES/scripts/functions.sh

# Add pre config
for file in $(find $ZDOTDIR/config -type f -name "pre*.zsh" ! -name "_*.zsh" | sort -n); do
  source "$file";
done

# For more plugins: https://github.com/unixorn/awesome-zsh-plugins
# More completions https://github.com/zsh-users/zsh-completions

ZSH_DISABLE_COMPFIX=true
HISTFILE="$ZDOTDIR/custom/.zsh_history"
setopt appendhistory

# some useful options (man zshoptions)
setopt autocd extendedglob nomatch menucomplete
setopt interactive_comments
zle_highlight=('paste:none')

# beeping is annoying
unsetopt BEEP

# completions
autoload -Uz compinit
zstyle ':completion:*' menu select
# zstyle ':completion::complete:lsof:*' menu yes select
zmodload zsh/complist
_comp_options+=(globdots)		# Include hidden files.

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Colors
autoload -Uz colors && colors

# Useful Functions
source "$ZDOTDIR/zsh-functions"

compinit

for file in $(find $ZDOTDIR/config -type f -name "*.zsh" ! -name "pre*.zsh" ! -name "post*.zsh" ! -name "_*.zsh" | sort -n); do
  source "$file";
done


zsh_add_file "zsh-exports"

# Key-bindings
# bindkey -s '^o' 'ranger^M'
# bindkey -s '^f' 'zi^M'
# bindkey -s '^s' 'ncdu^M'
# # bindkey -s '^n' 'nvim $(fzf)^M'
# # bindkey -s '^v' 'nvim\n'
# bindkey -s '^z' 'zi^M'
# bindkey '^[[P' delete-char
# bindkey "^p" up-line-or-beginning-search # Up
# bindkey "^n" down-line-or-beginning-search # Down
# bindkey "^k" up-line-or-beginning-search # Up
# bindkey "^j" down-line-or-beginning-search # Down
# bindkey -r "^u"
# bindkey -r "^d"

# Add post modules
for file in $(find $ZDOTDIR/config -type f -name "post*.zsh" ! -name "_*.zsh" | sort -n); do
  source "$file";
done

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
# bindkey '^e' edit-command-line

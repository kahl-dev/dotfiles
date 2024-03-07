#!/bin/bash

# Variable to enable/disable performance logging
# Set ZSH_PERFORMANCE_LOGGING=1 to enable logging
export ZSH_PERFORMANCE_LOGGING=0

# Check if performance logging is enabled
if [ "$ZSH_PERFORMANCE_LOGGING" -eq 1 ]; then
    # Start timing
    ZSHRC_START_TIME=$(date +%s%N)
fi

DOTFILES="$HOME/.dotfiles"

source $DOTFILES/scripts/config.sh
source $DOTFILES/scripts/functions.sh

# Add pre config
for file in $(find $ZDOTDIR/config -type f -name "pre*.zsh" ! -name "_*.zsh" | sort -n); do
  _log_performance "Log sourcing of $file" source "$file";
done

# For more plugins: https://github.com/unixorn/awesome-zsh-plugins
# More completions https://github.com/zsh-users/zsh-completions

ZSH_DISABLE_COMPFIX=true

setOptions () {
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
}

_log_performance "Log setting options" setOptions

# Useful Functions
_log_performance "Log sourcing zsh-functions" source "$ZDOTDIR/zsh-functions"

_log_performance "Log completion init" compinit

export PATH="$HOME/.local/bin":$PATH
export PATH="$DOTFILES/bin/dot":$PATH

for file in $(find $ZDOTDIR/config -type f -name "*.zsh" ! -name "pre*.zsh" ! -name "post*.zsh" ! -name "_*.zsh" | sort -n); do
  _log_performance "Log sourcing of $file" source "$file";
done

_log_performance "Log sourcing of zsh-exports" zsh_add_file "zsh-exports"

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
  _log_performance "Log sourcing of $file" source "$file";
done

# Edit line in vim with ctrl-e:
_log_performance "Log autoload edit-command-line" autoload edit-command-line; zle -N edit-command-line
# bindkey '^e' edit-command-line

# Check again if performance logging is enabled before calculating the duration
if [ "$ZSH_PERFORMANCE_LOGGING" -eq 1 ]; then
    # End timing and calculate the duration
    ZSHRC_END_TIME=$(date +%s%N)
    ZSHRC_DURATION=$((($ZSHRC_END_TIME - ZSHRC_START_TIME) / 1000000))
    echo "Total .zshrc execution time: $ZSHRC_DURATION ms"
fi

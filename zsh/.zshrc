# -----------------------------------------------------------------------------
# This file is sourced for interactive shell sessions.
# Place your interactive shell settings, aliases, functions, and key bindings here.
# It is sourced after ~/.zshenv and ~/.zprofile.
# -----------------------------------------------------------------------------

# https://www.youtube.com/watch?v=ud7YxC33Z3w
# https://github.com/dreamsofautonomy/zensh/blob/main/.zshrc

source $ZDOTDIR/utils.zsh
source "$ZDOTDIR/config/env.zsh"
source "$ZDOTDIR/config/zinit.zsh"
source "$ZDOTDIR/config/history.zsh"
source "$ZDOTDIR/config/node.zsh"

# Plugins and application files
source "$ZDOTDIR/config/neovim.zsh"
source "$ZDOTDIR/config/bat.zsh"
source "$ZDOTDIR/config/fzf.zsh"
source "$ZDOTDIR/config/plugins.zsh"

# Load completions
autoload -U compinit && compinit
zinit cdreplay -q

compdef mosh=ssh

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Make zsh know about hosts already accessed by SSH
zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

if command_exists brew; then
  GIT_EXTRAS_COMPLETION_PATH="$(brew --prefix)/opt/git-extras/share/git-extras/git-extras-completion.zsh"
  if file_exists "$GIT_EXTRAS_COMPLETION_PATH" && source "$GIT_EXTRAS_COMPLETION_PATH"
fi

zmodload zsh/complist

# Files needs to be loaded after completion or compinit
source "$ZDOTDIR/config/git-lia.zsh"
source "$ZDOTDIR/config/keybindings.zsh"
source "$ZDOTDIR/config/aliases.zsh"
source "$ZDOTDIR/config/prompt.zsh"

file_exists $HOME/.zshrc-local && source $HOME/.zshrc-local

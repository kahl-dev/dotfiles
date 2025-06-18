# -----------------------------------------------------------------------------
# This file is sourced for interactive shell sessions.
# Place your interactive shell settings, aliases, functions, and key bindings here.
# It is sourced after ~/.zshenv and ~/.zprofile.
# -----------------------------------------------------------------------------

# https://www.youtube.com/watch?v=ud7YxC33Z3w
# https://github.com/dreamsofautonomy/zensh/blob/main/.zshrc

source $ZDOTDIR/utils.zsh
source "$ZDOTDIR/config/zinit.zsh"
source "$ZDOTDIR/config/history.zsh"
source "$ZDOTDIR/config/node.zsh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Plugins and application files
source "$ZDOTDIR/config/neovim.zsh"
source "$ZDOTDIR/config/fzf.zsh"
source "$ZDOTDIR/config/atuin.zsh"
source "$ZDOTDIR/config/plugins.zsh"

# Enable useful options (see 'man zshoptions' for more details)
setopt autocd                # Automatically change to a directory if a command matches a directory name
setopt extendedglob          # Enable extended globbing syntax for advanced pattern matching
setopt nomatch               # Prevent errors when no matches are found for a glob pattern
setopt menucomplete          # Use arrow keys to cycle through completion options instead of showing a list
setopt interactive_comments  # Allow comments in interactive shells (lines starting with # are ignored)

# Optionally, disable highlighting of pasted text to avoid visual distractions
zle_highlight=('paste:none')

# Optionally, disable the terminal bell sound (beeping)
unsetopt BEEP

# Add completion functions provided by Homebrew
file_exists /opt/homebrew/share/zsh/site-functions/_brew ] && fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fpath=($DOTFILES/zsh/config/_dotbot_completion $fpath)

# Initialize and configure completions
autoload -Uz compinit       # Load the compinit function to initialize the completion system
compinit                    # Initialize the completion system
autoload -U +X bashcompinit && bashcompinit # Load bashcompinit for using Bash completion scripts in Zsh
zstyle ':completion:*' menu select          # Present a menu for selection when multiple completions are available
zmodload zsh/complist       # Load the complist module for advanced completion list features
_comp_options+=(globdots)   # Include hidden files (those starting with a dot) in glob patterns

# Enhance history navigation
autoload -U up-line-or-beginning-search     # Load the up-line-or-beginning-search function
autoload -U down-line-or-beginning-search   # Load the down-line-or-beginning-search function
zle -N up-line-or-beginning-search          # Define up-line-or-beginning-search as a ZLE widget
zle -N down-line-or-beginning-search        # Define down-line-or-beginning-search as a ZLE widget

# Enable and set up color definitions
autoload -Uz colors && colors               # Load and execute the colors function to set up color definitions

# Additional completion configurations
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' # Case-insensitive completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Use LS_COLORS for completion list coloring

# Make Zsh aware of hosts already accessed by SSH
zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts \
  'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

# Load Git extras completion if available
if command_exists brew; then
  GIT_EXTRAS_COMPLETION_PATH="$(brew --prefix)/opt/git-extras/share/git-extras/git-extras-completion.zsh"
  if file_exists "$GIT_EXTRAS_COMPLETION_PATH"; then
    source "$GIT_EXTRAS_COMPLETION_PATH"
  fi
fi

# Additional settings
zinit cdreplay -q                    # Load zinit cdreplay quietly
compdef mosh=ssh                     # Use ssh completion for mosh
zmodload zsh/complist                # Load the complist module for advanced completion list features

# Files needs to be loaded after completion or compinit
source "$ZDOTDIR/config/ngrok.zsh"
source "$ZDOTDIR/config/git-lia.zsh"
source "$ZDOTDIR/config/keybindings.zsh"
source "$ZDOTDIR/config/aliases.zsh"
source "$ZDOTDIR/config/prompt.zsh"
source "$ZDOTDIR/config/check_git_cleanup.zsh"

if [ -f "$HOME/.dotfiles-local/zshrc" ]; then
  source "$HOME/.dotfiles-local/zshrc"
elif [ -f "$HOME/.zshrc-local" ]; then
  source "$HOME/.zshrc-local"
fi

. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh)"

# fnm
FNM_PATH="/home/pi/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="/home/pi/.local/share/fnm:$PATH"
  eval "`fnm env`"
fi

# fnm
FNM_PATH="/home/pi/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="/home/pi/.local/share/fnm:$PATH"
  eval "`fnm env`"
fi

# fnm
FNM_PATH="/home/pi/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="/home/pi/.local/share/fnm:$PATH"
  eval "`fnm env`"
fi

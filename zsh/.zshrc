# -----------------------------------------------------------------------------
# This file is sourced for interactive shell sessions.
# Place your interactive shell settings, aliases, functions, and key bindings here.
# It is sourced after ~/.zshenv and ~/.zprofile.
# -----------------------------------------------------------------------------

# Exit early if not an interactive shell (prevents loading plugins in non-interactive contexts)
# [[ $- == *i* ]] || return

# https://www.youtube.com/watch?v=ud7YxC33Z3w
# https://github.com/dreamsofautonomy/zensh/blob/main/.zshrc

source $ZDOTDIR/utils.zsh
source "$ZDOTDIR/config/zinit.zsh"
source "$ZDOTDIR/config/history.zsh"

# Raspberry Pi: add fnm to PATH before node.zsh evaluates command_exists
# (fnm is installed at a non-standard path on Pi)
if ! command_exists mise; then
  FNM_PATH="/home/pi/.local/share/fnm"
  if [ -d "$FNM_PATH" ]; then
    export PATH="$FNM_PATH:$PATH"
  fi
fi

source "$ZDOTDIR/config/mise.zsh"
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

# Docker CLI completions
if command_exists docker; then
  DOCKER_COMPLETIONS_PATH="$HOME/.docker/completions"
  if [[ -d "$DOCKER_COMPLETIONS_PATH" ]]; then
    fpath=($DOCKER_COMPLETIONS_PATH $fpath)
  fi
fi

# Additional settings
zinit cdreplay -q                    # Load zinit cdreplay quietly
compdef mosh=ssh                     # Use ssh completion for mosh
zmodload zsh/complist                # Load the complist module for advanced completion list features

# Files needs to be loaded after completion or compinit
source "$ZDOTDIR/config/ngrok.zsh"
source "$ZDOTDIR/config/keybindings.zsh"
source "$ZDOTDIR/config/aliases.zsh"
source "$ZDOTDIR/config/worktree.zsh"
source "$ZDOTDIR/config/tmuxinator.zsh"
# source "$ZDOTDIR/config/claude-store.zsh"
source "$ZDOTDIR/config/ssh-agent.zsh"
source "$ZDOTDIR/config/remote-bridge.zsh"
source "$ZDOTDIR/config/claude-config.zsh"
source "$ZDOTDIR/config/prompt.zsh"
source "$ZDOTDIR/config/check_git_cleanup.zsh"
source "$ZDOTDIR/config/dot.zsh"

# LIT Tools - Personal productivity scripts for agency work
# See ~/repos/li-tools for database management, build tools, and git workflows
if [[ -d "$HOME/repos/li-tools" ]]; then
    source "$HOME/repos/li-tools/dotfiles/init.zsh"
fi

if [ -f "$HOME/.dotfiles-local/zshrc" ]; then
  source "$HOME/.dotfiles-local/zshrc"
elif [ -f "$HOME/.zshrc-local" ]; then
  source "$HOME/.zshrc-local"
fi

# LIA Cleanup Tool integration
[[ $- == *i* ]] && eval "$(lia-cleanup shell-hook 2>/dev/null)"

# bun completions
[ -s "/Users/kahl-dev/.bun/_bun" ] && source "/Users/kahl-dev/.bun/_bun"

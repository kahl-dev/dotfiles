# -----------------------------------------------------------------------------
# This file is sourced for all shell sessions, including interactive, login, and non-interactive shells.
# Place your universal environment variables here.
# It is sourced first, before ~/.zprofile, ~/.zshrc, and ~/.zlogin.
# -----------------------------------------------------------------------------


# Set DOTFILES to organize configuration files
export DOTFILES="$HOME/.dotfiles"

source $DOTFILES/zsh/utils.zsh

# Set ZDOTDIR to point to the .dotfiles zsh directory
export ZDOTDIR="$DOTFILES/zsh"

# Set XDG Base Directories explicitly
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# Universal environment variables
export HISTSIZE=10000
export HISTFILE="$ZDOTDIR/.zsh_history"
export SAVEHIST=$HISTSIZE

# Set the directory to store zinit and plugins
export ZINIT_ROOT="${XDG_DATA_HOME}/zinit"
export ZINIT_HOME="${ZINIT_ROOT}/zinit.git"

# Optional: Source .zprofile in non-login shells
# if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) && -s ${ZDOTDIR:-~}/.zprofile ]]; then
#   source ${ZDOTDIR:-~}/.zprofile
# fi

# Set Neovim as the pager for man pages
export MANPAGER='nvim +Man!'

# Set a high width for man page formatting to avoid line wrapping
export MANWIDTH=999

# Set Go workspace location
export GOPATH=$HOME/.local/share/go

# Allow Git to discover repositories across filesystem boundaries
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1

# Ensure Go binaries and user-installed binaries are in the PATH
export PATH=$HOME/.local/share/go/bin:$PATH
export PATH=$HOME/.local/bin:$PATH

# Add syntax highlighting to man pages
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

if is_macos; then
  export HOMEBREW_CASK_OPTS="--no-quarantine"
  export HOMEBREW_BUNDLE_FILE_GLOBAL="$DOTFILES/brew/osx/.Brewfile"
fi

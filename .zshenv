# -----------------------------------------------------------------------------
# This file is sourced for all shell sessions, including interactive, login, and non-interactive shells.
# Place your universal environment variables here.
# It is sourced first, before ~/.zprofile, ~/.zshrc, and ~/.zlogin.
# -----------------------------------------------------------------------------

# Set DOTFILES to organize configuration files
export DOTFILES="$HOME/.dotfiles"

source $DOTFILES/zsh/utils.zsh

typeset -U path
path=(
  "$ZINIT_ROOT/polaris/bin"
  "$DOTFILES/bin"
  ${(s.:.)PATH}  # This expands the current PATH into an array in Zsh
)

# Re-export the PATH from the path array
export PATH="${(j.:.)path}"

! command_exists git-lia && file_exists "$DOTFILES/bin/git-lia/git-lia" && path+=("$DOTFILES/bin/git-lia/git-lia")

path_exists "$DOTFILES/bin/nvim/bin/" && path+=("$DOTFILES/bin/nvim/bin")

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

# Allow Git to discover repositories across filesystem boundaries
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1

# Add syntax highlighting to man pages
if command_exists bat; then
  if command_exists fzf; then
    export FZF_PREVIEW_OPTS="bat {} || cat {} || tree -C {}"
    export FZF_CTRL_T_OPTS="--min-height 30 --preview-window down:60% --preview-window noborder --preview '($FZF_PREVIEW_OPTS) 2> /dev/null'"
  fi

  export NULLCMD=bat
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

if is_macos; then
  export HOMEBREW_CASK_OPTS="--no-quarantine"
  export HOMEBREW_BUNDLE_FILE_GLOBAL="$DOTFILES/brew/osx/.Brewfile"
  export HOMEBREW_UPGRADE_EXCLUDE_PACKAGES="elgato-wave-link elgato-stream-deck raycast aldente"
else
  export HOMEBREW_BUNDLE_FILE_GLOBAL="$DOTFILES/brew/linux/.Brewfile"
fi

# Prevent intelephense from crashing
export NODE_OPTIONS=--max_old_space_size=8192

export NODE_DEFAULT_PACKAGES="yarn prettier diff-so-fancy serve browser-sync neovim @antfu/ni @vue/language-server emmet-ls @tailwindcss/language-server @vtsls/language-server"

file_exists "$HOME/.dotfiles-local/.zshenv" && source "$HOME/.dotfiles-local/.zshenv"

export TERM=xterm-256color

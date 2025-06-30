# -----------------------------------------------------------------------------
# This file is sourced after ~/.zshrc during login shell sessions.
# Place commands you want to run once at login here.
# It is useful for commands that need to be run after the shell environment is set up.
# -----------------------------------------------------------------------------

source $ZDOTDIR/utils.zsh
command_exists neofetch && [[ $- == *i* ]] && neofetch

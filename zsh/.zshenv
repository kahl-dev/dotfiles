# ---- Default editors ---- #
export BROWSER="brave"
export TERMINAL="alacritty"

# ---- ZSH ---- #
export ZDOTDIR=${ZDOTDIR:-~/.config/zsh}
export HISTFILE="$ZDOTDIR/custom/.zsh_history"

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) && -s ${ZDOTDIR:-~}/.zprofile ]]; then
  source ${ZDOTDIR:-~}/.zprofile
fi

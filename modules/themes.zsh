# Powerlevel10k is a theme for Zsh. It emphasizes speed, flexibility and out-of-the-box experience.
# https://github.com/romkatv/powerlevel10k
zinit ice depth=1
zinit light romkatv/powerlevel10k

# An architecture for building themes based on carefully chosen syntax highlighting using a base of sixteen colors.
# Doc: https://github.com/chriskempson/base16
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  export BASE16_SHELL_SET_BACKGROUND=false
fi

# export BASE16_SHELL_HOOKS=$DOTFILES/base16_hooks
# export BASE16_FZF=${ZINIT[PLUGINS_DIR]}/fnune---base16-fzf/bash/

function base16ShellUpdate {
  # export FZF_DEFAULT_OPTS="$FZF_INIT_OPTS"
  # source $ZINIT[PLUGINS_DIR]/fnune---base16-fzf/bash/base16-$BASE16_THEME.config
  if [ -z "$TMUX" ]
  then
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
      cd ~ && tmux attach -t REMOTE || tmux new -s REMOTE
    else
      cd ~ && tmux attach -t LOCAL || tmux new -s LOCAL
    fi
  fi
}

zinit ice lucid atload"base16ShellUpdate"
zinit load chriskempson/base16-shell

# This ZSH plugin enhances the terminal environment with 256 colors.
# Doc: https://github.com/chrissicool/zsh-256color
zinit light "chrissicool/zsh-256color"

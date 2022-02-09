# Powerlevel10k is a theme for Zsh. It emphasizes speed, flexibility and out-of-the-box experience.
# Doc: https://github.com/romkatv/powerlevel10k
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM}/themes/powerlevel10k
fi
ZSH_THEME="powerlevel10k/powerlevel10k"

# An architecture for building themes based on carefully chosen syntax highlighting using a base of sixteen colors.
# Doc: https://github.com/chriskempson/base16
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  export BASE16_SHELL_SET_BACKGROUND=false
fi

# export BASE16_SHELL_HOOKS=$DOTFILES/base16_hooks
# export BASE16_FZF=${ZINIT[PLUGINS_DIR]}/fnune---base16-fzf/bash/

# function base16ShellUpdate {
#   export FZF_DEFAULT_OPTS="$FZF_INIT_OPTS"
#   source $ZINIT[PLUGINS_DIR]/fnune---base16-fzf/bash/base16-$BASE16_THEME.config
# }

# A shell script to change your shell's default ANSI colors but most
# importantly, colors 17 to 21 of your shell's 256 colorspace 
# Doc: https://github.com/chriskempson/base16-shell
if [ ! -d "$ZSH_CUSTOM/plugins/base16-shell" ]; then
  git clone https://github.com/chriskempson/base16-shell.git $ZSH_CUSTOM/plugins/base16-shell
fi
plugins+=(base16-shell)

# This ZSH plugin enhances the terminal environment with 256 colors.
# Doc: https://github.com/chrissicool/zsh-256color
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-256color" ]; then
  git clone --depth=1 https://github.com/chrissicool/zsh-256color ${ZSH_CUSTOM}/plugins/zsh-256color
fi
plugins+=(zsh-256color)
# Powerlevel10k is a theme for Zsh. It emphasizes speed, flexibility and out-of-the-box experience.
# Doc: https://github.com/romkatv/powerlevel10k
# zsh_add_plugin "romkatv/powerlevel10k"
# source $ZDOTDIR/plugins/powerlevel10k/powerlevel10k.zsh-theme
eval "$(starship init zsh)"

# An architecture for building themes based on carefully chosen syntax highlighting using a base of sixteen colors.
# Doc: https://github.com/chriskempson/base16
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  export BASE16_SHELL_SET_BACKGROUND=false
fi

# A shell script to change your shell's default ANSI colors but most
# importantly, colors 17 to 21 of your shell's 256 colorspace
# Doc: https://github.com/chriskempson/base16-shell
zsh_add_plugin "chriskempson/base16-shell"

# This ZSH plugin enhances the terminal environment with 256 colors.
# Doc: https://github.com/chrissicool/zsh-256color
zsh_add_plugin "chrissicool/zsh-256color"

# Powerlevel10k is a theme for Zsh. It emphasizes speed, flexibility and out-of-the-box experience.
# https://github.com/romkatv/powerlevel10k
zinit ice depth=1
zinit light romkatv/powerlevel10k

# An architecture for building themes based on carefully chosen syntax highlighting using a base of sixteen colors.
# Doc: https://github.com/chriskempson/base16
export BASE17_SHELL_SET_BACKGROUND=false
zinit ice wait"2" lucid
zinit load chriskempson/base16-shell

# This ZSH plugin enhances the terminal environment with 256 colors.
# Doc: https://github.com/chrissicool/zsh-256color
zinit light "chrissicool/zsh-256color"

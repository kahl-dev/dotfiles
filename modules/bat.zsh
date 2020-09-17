# Bat supports syntax highlighting for a large number of programming and markup languages
# https://github.com/sharkdp/bat

function initBat() {
  export BAT_CONFIG_PATH="$DOTFILES/ee/bat.conf"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"

  alias cat='bat';
}

zinit ice as"command" from"gh-r" mv"bat* -> bat" pick"bat/bat" atload"initBat"
zinit light sharkdp/bat

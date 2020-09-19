# Bat supports syntax highlighting for a large number of programming and markup languages
# https://github.com/sharkdp/bat

function initBat() {
  export FZF_PREVIEW_OPTS="bat {} || cat {} || tree -C {}"
  export FZF_CTRL_T_OPTS="--min-height 30 --preview-window down:60% --preview-window noborder --preview '($FZF_PREVIEW_OPTS) 2> /dev/null'"

  export BAT_CONFIG_PATH="$DOTFILES/config/bat.conf"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"

  alias cat='bat';
}

zinit ice as"command" from"gh-r" mv"bat* -> bat" pick"bat/bat" atload"initBat"
zinit light sharkdp/bat

# Use bat instead of cat
initBat() {

  if binaryExists bat; then
    export BAT_CONFIG_PATH="$DOTFILES/ee/bat.conf"
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export FZF_COMPLETION_OPTS="--preview '(bat --theme=\"base16\" --color=always --style=\"numbers,changes,header\" {} || cat {} || tree -C {}) 2> /dev/null | head -200'"
    export FZF_CTRL_T_OPTS="$FZF_COMPLETION_OPTS"

    alias cat='bat'; 
  fi

}

after_init+=(initBat)

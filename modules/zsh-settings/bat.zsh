# Use bat instead of cat
initBat() {

  if binaryExists bat; then
    export BAT_CONFIG_PATH="$DOTFILES/ee/bat.conf"
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    alias cat='bat'; 
  fi

}

after_init+=(initBat)

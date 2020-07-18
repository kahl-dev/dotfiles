# Use bat instead of cat
if which bat >/dev/null 2>&1; then
  export BAT_CONFIG_PATH="$DOTFILES/ee/bat.conf"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  alias cat='bat'; 
fi

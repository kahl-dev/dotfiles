if which tmux &> /dev/null; then
  plugins+=(tmux)

  ZSH_TMUX_AUTOSTART=true
  if [ "$(uname 2> /dev/null)" = "Darwin" ]; then
  ZSH_TMUX_AUTOQUIT=false
  fi
fi

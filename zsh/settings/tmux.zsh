if which tmux &> /dev/null; then
  plugins+=(tmux)

  # [[ $TMUX = "" ]] && export TERM="xterm-256color"
  # [[ $TMUX != "" ]] && export TERM="screen-256color"

  # ZSH_TMUX_AUTOSTART=true
  # if [ "$(uname 2> /dev/null)" = "Darwin" ]; then
  #   ZSH_TMUX_AUTOQUIT=false
  # fi
fi

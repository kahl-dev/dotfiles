if which tmux &> /dev/null; then
  plugins+=(tmux)


  if [ "$(uname 2> /dev/null)" = "Linux" ]; then
    # Launch SSH agent if not running
    if ! ps aux |grep $(whoami) |grep ssh-agent |grep -v grep >/dev/null; then ssh-agent ; fi

    # Link the latest ssh-agent socket
    ln -sf $(find /tmp -maxdepth 2 -type s -name "agent*" -user $USER -printf '%T@ %p\n' 2>/dev/null |sort -n|tail -1|cut -d' ' -f2) ~/.ssh/ssh_auth_sock

    export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
  fi

  # [[ $TMUX = "" ]] && export TERM="xterm-256color"
  # [[ $TMUX != "" ]] && export TERM="screen-256color"

  # ZSH_TMUX_AUTOSTART=true
  # if [ "$(uname 2> /dev/null)" = "Darwin" ]; then
  #   ZSH_TMUX_AUTOQUIT=false
  # fi
fi

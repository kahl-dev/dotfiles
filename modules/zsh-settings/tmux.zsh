if which tmux &> /dev/null; then
  plugins+=(tmux)

  # ZSH_TMUX_AUTOSTART=true

  # Attach or create tmux base session
  alias tmuxm='tmux attach -t main || tmux new -s main'

  # Update ssh session for tmux
  alias tmuxssh='eval $(tmux show-env -s |grep "^SSH_")'
fi

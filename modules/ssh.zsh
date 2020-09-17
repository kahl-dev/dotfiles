if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  export SSH_AUTH_SOCK=$HOME/.ssh/ssh_auth_sock
fi

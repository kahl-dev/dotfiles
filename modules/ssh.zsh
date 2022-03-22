# Look into tmux remote
# if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
#   export SSH_AUTH_SOCK=$HOME/.ssh/ssh_auth_sock
# fi
#

# Add 1password support for ssh
if [ "$(uname)" = "Darwin" ]; then
  if [ -d "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t" ]; then
    if [ ! -L "$HOME/.1password/agent.sock" ]; then
      mkdir -p ~/.1password && ln -s ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ~/.1password/agent.sock
    fi

    if [ -L "$HOME/.1password/agent.sock" ]; then
      export SSH_AUTH_SOCK=~/.1password/agent.sock
    fi
  fi
fi

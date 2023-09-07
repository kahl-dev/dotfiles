export NC_LISTENER_HOST_PORT=20502
export NC_LISTENER_REMOTE_PORT=20502
# if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  export PATH="$DOTFILES/bin/nc_listener:${PATH}"
# fi

# xdg-open() {
#   open $@
# }



if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  export PATH=$PATH:$DOTFILES/bin/open
else
  export NC_LISTENER_HOST_PORT=20502
  alias st3='ssh -R 20502:127.0.0.1:$NC_LISTENER_HOST_PORT typo3.dev'
fi

xdg-open() {
  open $@
}


if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  export PATH=$PATH:$DOTFILES/bin/open
fi

xdg-open() {
  open $@
}


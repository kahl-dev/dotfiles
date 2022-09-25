# npm list without dependencies
alias npmLs="npm ls --depth=0 "$@" 2>/dev/null"
alias npmLsg="npm ls -g --depth=0 "$@" 2>/dev/null"

npmid() {
  cat $DOTFILES/config/default-packages | xargs npm install -g
}

# npm list without dependencies
alias npmLs="npm ls --depth=0 "$@" 2>/dev/null"
alias npmLsg="npm ls -g --depth=0 "$@" 2>/dev/null"

npmid() {
  cat $DOTFILES/config/default-packages | xargs npm install -g
}

alias ya="yarn add"
alias y="yarn"
alias yb="yarn build"
alias yd="yarn dev"
alias yi="yarn"
alias yin="yarn install"

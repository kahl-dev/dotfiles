alias cdtl='cd "$(git rev-parse --show-toplevel)"'
alias marked='open -a "Marked 2"'
alias prettier-js='prettier --single-quote --trailing-comma none --bracket-spacing --jsx-bracket-same-line true --parser flow --write "**/*.js"'
if [ "$(uname 2> /dev/null)" = "Linux" ]; then
  alias vim="${HOME}/.linuxbrew/bin/vim"
fi
alias agrep='alias | grep'

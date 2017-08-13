# go to git root dir
alias cdtl='cd "$(git rev-parse --show-toplevel)"'

# grep all aliases
alias agrep='alias | grep'

# npm list without dependencies
alias npmLs="npm ls --depth=0 "$@" 2>/dev/null"

# linux only
if [ "$(uname 2> /dev/null)" = "Linux" ]; then

  # use newer vim instead
  alias vim="${HOME}/.linuxbrew/bin/vim"
fi

# os x only
if [ "$(uname 2> /dev/null)" = "Darwin" ]; then

  # add markdownreader app
  alias marked='open -a "Marked 2"'
fi


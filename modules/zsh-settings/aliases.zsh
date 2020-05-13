# Go to git root dir
alias cdtl='cd "$(git rev-parse --show-toplevel)"'

# Grep all aliases
alias agrep='alias | grep'

# Git update submodules recursive
alias gsur="git submodule update --recursive --remote --merge --init"

# Os x only
if [ "$(uname 2> /dev/null)" = "Darwin" ]; then

  # Add markdownreader app
  alias marked='open -a "Marked 2"'

  # alias vim='mvim -v'
fi

# Open better manual/help than man
if which tldr >/dev/null 2>&1; then alias help='tldr'; fi

# Use bat instead of cat
if which bat >/dev/null 2>&1; then alias cat='bat'; fi

# Echo current base16 theme
alias theme='echo $BASE16_THEME'

if which nvim >/dev/null 2>&1; then alias vim='nvim'; fi
alias vi='vim'

alias ssh="TERM=xterm-256color ssh"

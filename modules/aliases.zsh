# Go to git root dir
alias ..='cd ..'
alias cdtl='cd "$(git rev-parse --show-toplevel)"'

# Grep all aliases
alias agrep='alias | grep'

# Git update submodules recursive
# alias gsur="git submodule update --recursive --remote --merge --init"

# Os x only
if [ "$(uname 2> /dev/null)" = "Darwin" ]; then

  # Add markdownreader app
  alias marked='open -a "Marked 2"'
fi

# Echo current base16 theme
alias theme='echo $BASE16_THEME'

# alias ssh="TERM=xterm-256color ssh"

alias myip="curl http://ipecho.net/plain; echo"

# Check if main exists and use instead of master
function git_main_branch() {
  if [[ -n "$(git branch --list main)" ]]; then
    echo main
  else
    echo master
  fi
}

alias dotfiles="vim ~/.dotfiles"

alias gbrclean='git fetch --prune && git branch -r | awk "{print \$1}" | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk "{print \$1}" | xargs git branch -D'

alias ryid='rm -Rf node_modules && yarn install && yarn dev'
alias ryib='rm -Rf node_modules && yarn install && yarn build'

alias base16color='curl -s https://gist.githubusercontent.com/HaleTom/89ffe32783f89f403bba96bd7bcd1263/raw/ | bash'

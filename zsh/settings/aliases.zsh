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

alias vi='vim'

alias ssh="TERM=xterm-256color ssh"

alias clip="nc localhost 8377"

alias falias='alias | fzf'

# fzf tmux
alias ft="fzf_tmux"
alias ftp="fzf_tmux_pane"

# fzf git
alias fgl='fzf_git_log'
alias fgbr='fzf_git_branch'
alias fgco='fzf_git_checkout'
alias fgst='fzf_git_stash'
alias fga='fzf_git_add'


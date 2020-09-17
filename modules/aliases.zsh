# Go to git root dir
alias cdtl='cd "$(git rev-parse --show-toplevel)"'
alias ..='cd ..'

# Grep all aliases
alias agrep='alias | grep'

# Git update submodules recursive
alias gsur="git submodule update --recursive --remote --merge --init"

# Os x only
if [ "$(uname 2> /dev/null)" = "Darwin" ]; then

  # Add markdownreader app
  alias marked='open -a "Marked 2"'
fi

# Echo current base16 theme
alias theme='echo $BASE16_THEME'

alias vi='vim'

# alias ssh="TERM=xterm-256color ssh"

# alias vim="ASDF_NODEJS_VERSION=14.4.0 vim"

alias l="ls -la"

alias gsb="git status -b"

alias g=git
alias ga='git add'
alias gaa='git add --all'
alias gam='git am'
alias gapa='git add --patch'
alias gb='git branch'
alias gbD='git branch -D'
alias gbd='git branch -d'

alias gco='git checkout'

alias gd='git diff'

alias glg='git log --stat'
alias glgg='git log --graph'
alias glgga='git log --graph --decorate --all'
alias glgm='git log --graph --max-count=10'
alias glgp='git log --stat -p'
alias glo='git log --oneline --decorate'
alias globurl='noglob urlglobber '
alias glod='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'\'
alias glods='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'\'' --date=short'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glol='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'
alias glola='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'' --all'
alias glols='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'' --stat'

alias gm='git merge'

alias gp='git push'

alias gsb='git status -sb'

alias gsta='git stash push'
alias gstaa='git stash apply'
alias gstall='git stash --all'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show --text'
alias gstu='git stash --include-untracked'

alias gsu='git submodule update'
alias gsur='git submodule update --recursive --remote --merge --init'

alias l='ls -lah'
alias ls='ls -G'

alias md='mkdir -p'
alias rd='rmdir'

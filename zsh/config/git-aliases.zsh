# Git version checking
autoload -Uz is-at-least
git_version="${${(As: :)$(git version 2>/dev/null)}[3]}"

#
# Functions
#

# Pretty log messages
function _git_log_prettily(){
  if ! [ -z $1 ]; then
    git log --pretty=$1
  fi
}
compdef _git _git_log_prettily=git-log

# Check if main exists and use instead of master
function git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local ref
  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk}; do
    if command git show-ref -q --verify $ref; then
      echo ${ref:t}
      return
    fi
  done
  echo master
}

# Check for develop and similarly named branches
function git_develop_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local branch
  for branch in dev devel development; do
    if command git show-ref -q --verify refs/heads/$branch; then
      echo $branch
      return
    fi
  done
  echo develop
}

function git_production_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local branch
  for branch in online; do
    if command git show-ref -q --verify refs/heads/$branch; then
      echo $branch
      return
    fi
  done
  echo production
}

function git_check_if_merged() {
# Determine the main or master branch dynamically
local main_branch=$(git_main_branch)
# Get the current branch name
local current_branch=$(git branch --show-current)

# Fetch the latest changes for main or master branch
git fetch origin $main_branch:$main_branch

# Check if the current branch is fully merged into the main or master branch
if git branch --merged | grep -qE "^ *($main_branch)$"; then
  echo "Current branch $current_branch is fully merged into $main_branch."
else
  echo "Current branch $current_branch is NOT fully merged into $main_branch."
  echo "Listing commits in $current_branch that are not in $main_branch:"
  git log $main_branch..$current_branch --oneline
fi
}

#
# Aliases
# (sorted alphabetically)
#

alias g='git'

alias ga='git add'
alias gaa='git add --all'

alias gba='git branch -a'

alias gcheckmerged='git_check_if_merged'
alias gcl='git clone --recurse-submodules'
alias gclean='git clean -id'
alias gcm='git checkout $(git_main_branch)'
alias gcd='git checkout $(git_develop_branch)'
alias gcp='git checkout $(git_production_branch)'
alias gc='git commit -v'
alias gcmsg='git commit -m'

if alias gco > /dev/null 2>&1; then
  unalias gco
fi
alias gco="git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short) - (%(authorname) %(committerdate:relative))' | fzf --header \"Checkout Recent Branch\" --preview \"git diff {1} --color=always\" --pointer=\"\" | xargs git checkout"

alias gd='git diff'

function gdnolock() {
  git diff "$@" ":(exclude)package-lock.json" ":(exclude)*.lock"
}

alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
alias gpsup='git push --set-upstream origin $(git_current_branch)'

alias ghh='git help'

alias glol="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'"
alias glola="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --all"
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glp="_git_log_prettily"

alias gm='git merge'
alias gdp='git up; git checkout $(git_production_branch); git up; git merge --commit --no-edit $(git_main_branch); git push; git checkout $(git_main_branch)'
alias gdpg='gdp; make glab-production'

alias gp='git push'

alias gsb='git status -sb'
alias gss='git status -s'

# use the default stash push on git 2.13 and newer
is-at-least 2.13 "$git_version" \
  && alias gsta='git stash push' \
  || alias gsta='git stash save'

alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show --text'

# Go to git root dir
alias cdgr='cd "$(git rev-parse --show-toplevel)"'

alias gup='git up'
alias gupdate='git update'
alias gbrclean='git fetch --prune && git branch -r | awk "{print \$1}" | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk "{print \$1}" | xargs git branch -D'

function grename() {
  if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: $0 old_branch new_branch"
    return 1
  fi

  # Rename branch locally
  git branch -m "$1" "$2"
  # Rename branch in origin remote
  if git push origin :"$1"; then
    git push --set-upstream origin "$2"
  fi
}

unset git_version


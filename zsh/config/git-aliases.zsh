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

#
# Aliases
# (sorted alphabetically)
#

alias g='git'

alias ga='git add'
alias gaa='git add --all'

alias gba='git branch -a'

alias gcl='git clone --recurse-submodules'
alias gclean='git clean -id'
alias gcm='git checkout $(git_main_branch)'
alias gcd='git checkout $(git_develop_branch)'
alias gcp='git checkout $(git_production_branch)'
alias gc='git commit -v'
alias gcmsg='git commit -m'
alias gco='git checkout'

git_recent() {
    # List all branches, keeping 'origin/' prefix for remote branches without a local equivalent
    git for-each-ref --sort=-committerdate --format='%(refname:short) - (%(authorname) %(committerdate:relative))' refs/heads/ refs/remotes/ | \
    awk -F' - ' '{
        # Remove the 'origin/' prefix for processing but keep it for display
        original=$1; gsub(/^origin\//, "", $1);
        if (!seen[$1]++) {
            # If this is the first occurrence of the branch, print it with its original prefix
            print original" - "$2
        }
    }' | \
    # Use fzf for interactive branch selection with a preview of the branch's last commit
    fzf --header "Checkout Recent Branch" --preview "git show --color=always --pretty=format:'%C(red)%h%Creset -%C(yellow)%d%Creset %s %C(green)(%cr) %C(bold blue)<%an>%Creset' {1}" --pointer="" | \
    # Extract the selected branch name
    awk -F' - ' '{print $1}' | \
    # Checkout the selected branch, creating a new local branch if it's a remote branch
    xargs -I {} bash -c 'branch="{}"; if git show-ref --verify --quiet refs/heads/$branch; then git checkout $branch; else git checkout -b "${branch#origin/}" --track "$branch"; fi'
}
alias gr='git_recent'

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


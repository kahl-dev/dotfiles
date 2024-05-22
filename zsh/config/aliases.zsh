_mkcd() {
  mkdir -p "$@" && cd "$_"
}

alias mkcd="_mkcd"
alias c='clear'
alias x='exit'
alias ll="ls -lAFh --color"
alias l="ll"
alias ls="ls -AFh --color"
alias help='man'
alias rm='rm -i'
alias t='tail -f'
alias grep='grep --color'
alias sgrep='grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} '
alias myip="curl http://ipecho.net/plain; echo" # Get my ip
alias df='df -h'                                # human-readable disk usage
alias psmem='ps aux | sort -nrk 4 | head -5'
alias pscpu='ps aux | sort -nrk 3 | head -5'

# ############################## #
# FZF
# ############################## #

if command_exists fzf; then
  alias fa='alias | fzf-tmux'
  alias s='_s'
fi

# ############################## #
# Makefiles
# ############################## #

# Function to run 'make install' if an 'install' target is defined in the Makefile
_mi() {
  if [ -f Makefile ] && grep -q "^install:" Makefile; then
    make install
  else
    echo "No Makefile found or no install command defined"
  fi
}

# Function to run 'make build' if a 'build' target is defined in the Makefile
_mb() {
  if [ -f Makefile ] && grep -q "^build:" Makefile; then
    make build
  else
    echo "No Makefile found or no build command defined"
  fi
}

# Function to run 'make dev' or 'make develop' based on available targets in the Makefile
_md() {
  if [ -f Makefile ]; then
    if grep -q "^dev:" Makefile; then
      make dev
    elif grep -q "^develop:" Makefile; then
      make develop
    else
      echo "No dev or develop command defined in Makefile"
    fi
  else
    echo "No Makefile found"
  fi
}

alias mi='_mi'
alias mb='_mb'
alias md='_md'

# ############################## #
# Applications
# ############################## #

# browser-sync
command_exists browser-sync && alias bs='browser-sync'

# tmux
alias tmux-clear-resurrect='rm -rf ~/.tmux/resurrect/* && echo "Cleared all tmux-resurrect entries!"'

if command_exists fzf; then
  alias tm='_tm'
fi

# lazygit
command_exists lazygit && alias lg='lazygit'

# Neofetch
command_exists neofetch && alias info='neofetch'

# Neovim
if command_exists nvim; then
  alias v='nvim'
  alias vim='nvim'
  alias vimdiff='nvim -d'
fi

# Bat
if command_exists bat; then
  alias bat='bat'
  alias taillog='tail -f "$@" | bat --paging=never -l log'
fi

# Btop
if command_exists btop; then
  alias top='btop'
  alias htop='btop'
fi

# Brew
if command_exists brew; then
  alias brewup='brew update; brew upgrade; brew cleanup'
  alias brewdump='brew bundle dump --force --describe --file=$HOMEBREW_BUNDLE_FILE_GLOBAL'
fi

# Eza
if command_exists eza; then
  alias ll="eza -lAhF --git"
  alias ls="eza -AhF"
fi

# ############################## #
# Git
# ############################## #

# Many of these aliases are taken from the oh-my-zsh git plugin but modified to
# fit my needs.
# https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh

# Git version checking
autoload -Uz is-at-least
git_version="${${(As: :)$(git version 2>/dev/null)}[3]}"

# Pretty log messages
_git_log_prettily(){
  if ! [ -z $1 ]; then
    git log --pretty=$1
  fi
}
compdef _git _git_log_prettily=git-log

# Check if main exists and use instead of master
_git_main_branch() {
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
_git_develop_branch() {
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

_git_production_branch() {
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

_git_recent() {
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
    fzf-tmux ${FZF_TMUX_OPTS} --header "Checkout Recent Branch" --preview "git show --color=always --pretty=format:'%C(red)%h%Creset -%C(yellow)%d%Creset %s %C(green)(%cr) %C(bold blue)<%an>%Creset' {1}" --pointer="" | \
    # Extract the selected branch name
    awk -F' - ' '{print $1}' | \
    # Checkout the selected branch, creating a new local branch if it's a remote branch
    xargs -I {} bash -c 'branch="{}"; if git show-ref --verify --quiet refs/heads/$branch; then git checkout $branch; else git checkout -b "${branch#origin/}" --track "$branch"; fi'
}

function _grename() {
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

_gjirab() {
  local branch_name=$(git branch --show-current)
  local ticket_id=$(echo "$branch_name" | grep -oE '[A-Z]+-[0-9]+' | head -n 1)
  if [[ -n "$ticket_id" ]]; then
    local jira_url="${JIRA_WORKSPACE}/browse/${ticket_id}"
    handle_clipboard.sh "$jira_url"
  else
    echo "No JIRA ticket found in the branch name."
  fi
}

_gjirac() {
  local commit_hash=$(git log -10 --pretty='%h %s' | fzf-tmux ${FZF_TMUX_OPTS} --no-multi | awk '{print $1}')
  if [[ -n "$commit_hash" ]]; then
    local ticket_id=$(git log -1 --format=%B "$commit_hash" | grep -oE '([A-Z]+-[0-9]+)' | head -n 1)
    if [[ -n "$ticket_id" ]]; then
      local jira_url="${JIRA_WORKSPACE}/browse/${ticket_id}"
      handle_clipboard.sh "$jira_url"
    else
      echo "No JIRA ticket found in the commit message."
    fi
  else
    echo "No commit selected."
  fi
}

alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gba='git branch -a'
alias gcl='git clone --recurse-submodules'
alias gclean='git clean -d -f'

alias gc='git commit -v'
alias gcmsg='git commit -m'

alias gcm='git checkout $(_git_main_branch)'
alias gcd='git checkout $(_git_develop_branch)'
alias gcp='git checkout $(_git_production_branch)'
alias gco='git checkout'
alias gcol="git checkout @{-1}" # checkout the last branch
alias gr='_git_recent'

alias gd='git diff'

function _gdnolock() {
  git diff "$@" ":(exclude)package-lock.json" ":(exclude)*.lock"
}
alias gdnolock="_gdnolock"

alias ggsup='git branch --set-upstream-to=origin/$(_git_current_branch)'
alias gpsup='git push --set-upstream origin $(_git_current_branch)'

alias ghh='git help'

alias glol="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'"
alias glola="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --all"
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glp="_git_log_prettily"

alias gm='git merge'
alias gml='git merge @{-1}'
alias gdp='git up; git checkout $(_git_production_branch); git up; git merge --commit --no-edit $(_git_main_branch); git push; git checkout $(_git_main_branch)'
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
alias groot='cd "$(git rev-parse --show-toplevel)"'

alias gup='git up'
alias gupdate='git update'
alias gbrclean='git fetch --prune && git branch -r | awk "{print \$1}" | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk "{print \$1}" | xargs git branch -D'

alias grename="_grename"

unset git_version

alias gjirab="_gjirab"
alias gjirac="_gjirac"

# ############################## #
# macOS Specific Aliases
# ############################## #

if is_macos; then

  # Add markdownreader app
  _marked() {
    if [ "$1" ]; then
      open -a "marked 2.app" "$1"
    else
      open -a "marked 2.app"
    fi
  }

  alias marked="_marked"

fi

# ############################## #
# Dotfiles
# ############################## #

alias dot='vim ${DOTFILES}'
alias zshrc='vim ${ZDOTDIR}/.zshrc'

_zsh-reload-all() {
  zinit self-update
  zinit update --all
  source $ZDOTDIR/.zshenv
  source $ZDOTDIR/.zprofile
  source $ZDOTDIR/.zshrc
  source $ZDOTDIR/.zlogin
  source $ZDOTDIR/.zlogout
}

_zsh-reset() {
  rm -rf $ZINIT_ROOT/plugins
  rm -rf $ZINIT_ROOT/snippets
  rm -rf $ZINIT_ROOT/completions
  source $ZDOTDIR/.zshrc
}

_dot-clean-home() {
  # Find all zsh files, directories, and symlinks in the home directory
  zsh_items=$(find "$HOME" -maxdepth 1 \( -name ".zsh*" -o -name "*.zsh" \) -not -name ".zshenv")

  # Check if there are any items to delete
  if [ -z "$zsh_items" ]; then
    echo "No zsh-related files, directories, or symlinks found to remove."
    return
  fi

  # Loop through the items and remove them
  echo "Removing the following zsh-related items:"
  echo "$zsh_items"
  echo "$zsh_items" | while read -r item; do
    rm -rf "$item"
  done

  echo "Cleanup complete."
}

alias zsh-reload='source $ZDOTDIR/.zshrc'
alias zsh-reload-all='_zsh-reload-all'
alias zsh-reset='_zsh-reset'
alias dot-clean-home='_dot-clean-home'

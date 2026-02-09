#!/usr/bin/env zsh

_mkcd() {
  mkdir -p "$@" && cd "$_"
}

_cx() {
  cd "$@" && ls
}

# Source dotfiles completion script for install-profile and install-standalone
if [[ -f "$DOTFILES/completion/dotfiles-completion.bash" ]]; then
  if [[ -n "${BASH_VERSION:-}" ]]; then
    source "$DOTFILES/completion/dotfiles-completion.bash"
  elif [[ -n "${ZSH_VERSION:-}" ]]; then
    if ! whence complete >/dev/null 2>&1; then
      (( $+functions[compinit] )) || autoload -Uz compinit
      compinit >/dev/null 2>&1 || true
      (( $+functions[bashcompinit] )) || autoload -Uz bashcompinit
      bashcompinit >/dev/null 2>&1 || true
    fi

    if whence complete >/dev/null 2>&1; then
      source "$DOTFILES/completion/dotfiles-completion.bash"
    fi
  fi
fi

alias ..='cd ..'
alias ...='cd ../..'

# Claude Code Dashboard System - removed, files deleted

# Tmux Custom Status Bar
alias tmux-status-reload='tmux source-file ~/.dotfiles/tmux/custom-status.conf'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias mkcd="_mkcd"
alias cx="_cx"
alias c='clear'
alias x='exit'
alias cl='clear'
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
alias trail='<<<${(F)path}'

# ############################## #
# FZF
# ############################## #

if command_exists fzf; then
  _fcd() {
    cd "$(find . -type d -not -path '*/.*' -not -path '*/node_modules/*' | fzf)" && ls;
  }


  _fa() {
    local selected=$(alias | sed 's/^alias //' | awk -F= '{printf "%-20s %s\n", $1, $2}' | fzf-tmux ${FZF_TMUX_OPTS} --header="🔍 Find Aliases" --preview 'echo "Command: {2..}"' --preview-window=down:1 | awk '{print $1}')
    if [[ -n "$selected" ]]; then
      eval "$selected"
    fi
  }
  alias fa='_fa'
  alias s='_s'
  alias fcd='_fcd'
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

alias m='make'
alias mi='_mi'
alias mb='_mb'
alias md='_md'

# ############################## #
# Applications
# ############################## #

# browser-sync
command_exists browser-sync && alias bs='browser-sync'

command_exists yazi && alias y='yazi'

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

# Cursor
if command_exists cursor-agent; then
  alias cursor='cursor-agent'
fi

# Bat
if command_exists bat; then
  alias cat='bat --paging=never'
  alias less='bat'
  alias more='bat'
  _taillog() {
    tail -f "$@" | bat --paging=never -l log
  }
  alias taillog='_taillog'
fi

# Btop
if command_exists btop; then
  alias top='btop'
  alias htop='btop'
fi

# Brew
if command_exists brew; then
  # Deprecated: use 'dot brew update'
  alias brewup='brew update; brew upgrade $(brew list --formula); brew cleanup'
  alias brewupCask='brew update; brew upgrade $(brew list | grep --invert-match $HOMEBREW_UPGRADE_EXCLUDE_PACKAGES); brew cleanup'
  # Deprecated: use 'dot brew dump'
  alias brewdump='brew bundle dump --force --describe --file=$HOMEBREW_BUNDLE_FILE_GLOBAL'
fi

# Eza
if command_exists eza; then
  eza_params=('--git' '--icons' '--classify' '--group-directories-first' '--group' '--color-scale')

  alias ls='eza -AhF ${eza_params}'
  alias l='ll'
  alias ll='eza --all --header --long ${eza_params}'
  alias llm='eza --all --header --long --sort=modified ${eza_params}'
  alias la='eza -lbhHigUmuSa'
  alias lx='eza -lbhHigUmuSa@'
  alias lt='ll --tree --ignore-glob node_modules --level=2'
  alias tree='eza --tree --ignore-glob node_modules'
fi

# ############################## #
# Node/NPM/Yarn
# ############################## #

# install default packages from $DOTFILES/config/default-packages
_npm_install_global_default() {
  echo "$NODE_DEFAULT_PACKAGES" | xargs npm install -g
}

# npm aliases (complement ni ecosystem)
alias nls='npm ls --depth=0 2>/dev/null'        # List local packages
alias nlsg='npm ls -g --depth=0 2>/dev/null'    # List global packages
alias nout='npm outdated'                       # Check outdated local packages
alias noutg='npm outdated -g --depth=0'         # Check outdated global packages
alias nup-local='npx npm-check -u'              # Interactive local updates
alias nup-global='npx npm-check -g -u'          # Interactive global updates
alias npmid=_npm_install_global_default

# alias ya="yarn add"
# alias y="yarn"
# alias yb="yarn build"
# alias yd="yarn dev"
# alias yi="yarn"
# alias yin="yarn install"

if command_exists fnm; then
  alias fnm_uninstall_all=_fnm_uninstall_all
  alias fnm_install_latest=_fnm_install_latest
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

# Function to view diffs with preview and open selected files in the editor
_gitdiffview() {
  local branch repo_root
  branch=$(_git_main_branch)
  repo_root=$(git rev-parse --show-toplevel)
  FZF_TMUX= git -C "$repo_root" diff --name-only "$branch" | fzf --multi --preview "git -C $repo_root diff --color=always $branch -- {}" | xargs -r $EDITOR
}

# Show git diff to base branch as fzf preview
alias gitdiffview='_gitdiffview'
alias gdv='_gitdiffview'

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
alias gpcc='git push -o ci.variable="CLEAR_CACHE=1"'

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
alias cdgr='cd "$(git rev-parse --show-toplevel)"'

alias gup='git up'
alias gupdate='git update'
alias gbrclean='git fetch --prune && git branch -r | awk "{print \$1}" | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk "{print \$1}" | xargs git branch -D'

alias grename="_grename"

unset git_version

alias gjirab="_gjirab"
alias gjirac="_gjirac"

# Claude Code commit helper
alias gcommit='claude -p "/commit"'

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
# Work Specific Aliases
# ############################## #

# Execute the make sitebase command to get the URL and copy it to the clipboard
alias lia-copyurl="{
  if ! command -v make &> /dev/null; then
    echo 'Error: make command not found.' >&2
    return 1
  fi

  output=\$(make sitebase 2>&1)
  if [[ \$? -ne 0 ]]; then
    echo 'Error: make sitebase command failed.' >&2
    echo \"\$output\" >&2
    return 1
  fi

  selected_url=\$(echo \"\$output\" | grep -oP '(http|https)://[^ ]+' | sed 's/\[[0-9;]*m//g' | fzf-tmux)

  if [[ -n \"\$selected_url\" ]]; then
    # Use rclip for clipboard operations - it handles local/remote automatically
    echo \"\$selected_url\" | rclip
    echo \"Selected URL: \$selected_url\"
  fi
}"
alias lcu='lia-copyurl'

# ############################## #
# Podman (Docker replacement)
# ############################## #

# if command_exists podman; then
#   alias docker='podman'
#
#   # Override docker-compose if podman-compose is available
#   command_exists podman-compose && alias docker-compose='podman-compose'
#
#   # Podman-specific aliases
#   alias podman-clean='podman system prune -a'
#   alias podman-clean-all='podman system prune -a --volumes'
#   alias podman-reset='podman system reset'
# fi

# ############################## #
# Atuin Environment Variables
# ############################## #

# Quick access to atuin env var commands
alias av='atuin dotfiles var'
alias avs='atuin dotfiles var set'
alias avl='atuin dotfiles var list'
alias avd='atuin dotfiles var delete'

# Interactive env var setter with confirmation
_avset() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: avset KEY VALUE"
    return 1
  fi
  
  local key="$1"
  local value="$2"
  
  echo "Setting environment variable:"
  echo "  Key: $key"
  echo "  Value: ${value:0:20}${#value -gt 20 && echo "..."}"
  read -q "REPLY?Continue? (y/n): "
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    atuin dotfiles var set "$key" "$value"
    echo "✅ Set $key"
  else
    echo "❌ Cancelled"
  fi
}

# Interactive env var deleter with confirmation
_avdel() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: avdel KEY"
    return 1
  fi
  
  local key="$1"
  
  echo "Deleting environment variable: $key"
  read -q "REPLY?Are you sure? (y/n): "
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    atuin dotfiles var delete "$key"
    echo "✅ Deleted $key"
  else
    echo "❌ Cancelled"
  fi
}

# Show env vars with nice formatting
_avshow() {
  echo "🔑 Atuin Environment Variables:"
  echo "================================"
  atuin dotfiles var list
}

alias avset='_avset'
alias avdel='_avdel'
alias avshow='_avshow'

# Atuin sync shortcuts
alias async='atuin sync'
alias astatus='atuin status'

# ############################## #
# Remote Bridge Clipboard Aliases
# ############################## #

# Make clipboard tools use rclip for remote compatibility
if command_exists rclip; then
  # Common clipboard commands mapped to rclip
  alias xclip='rclip'
  alias xsel='rclip'
  alias wl-copy='rclip'
  alias pbcopy='rclip'
  
  # For commands that expect stdin by default
  alias 'xclip -selection clipboard'='rclip'
  alias 'xclip -sel clip'='rclip'
  alias 'xsel --clipboard'='rclip'
  alias 'xsel -b'='rclip'
fi

# ############################## #
# AeroSpace
# ############################## #

alias as='aerospace'
ff() {
    aerospace list-windows --all | fzf --bind 'enter:execute(bash -c "aerospace focus --window-id {1}")+abort'
}

alias mcc='make clearcache'

# ############################## #
# Claude
# ############################## #

# Claude aliases
alias cc='claude -c'
alias ccu='npx ccusage'
alias cyolo='claude --dangerously-skip-permissions'  # Sandbox auto-enabled via settings.json

# ############################## #
# Dotfiles
# ############################## #

# Deprecated: use 'dot edit'
alias dotedit='cd ${DOTFILES} && v'
alias zshrc='vim ${ZDOTDIR}/.zshrc'


# Update zinit and all plugins
_zsh-update() {
  echo "Updating zinit..."
  if ! zinit self-update; then
    echo "zinit self-update failed!" >&2
    return 1
  fi

  echo "Updating all plugins..."
  if ! zinit update --all; then
    echo "zinit update failed!" >&2
    return 1
  fi
  echo "Update complete."
}

# Reload all Zsh configurations
_zsh-reload-all() {
  local ZSH_ENV="${ZDOTDIR:-$HOME/.zshenv}"
  echo "Sourcing $ZSH_ENV..."
  source "$ZSH_ENV"

  for file in .zprofile .zshrc .zlogin .zlogout; do
    local config_file="${ZDOTDIR:-$HOME}/$file"
    if [[ -f "$config_file" ]]; then
      echo "Sourcing $config_file..."
      source "$config_file"
    else
      echo "Warning: $config_file not found!" >&2
    fi
  done

  echo "Reload complete."
}

# Deprecated: use 'dot shell reload'
alias zsh-reload='source $ZDOTDIR/.zshrc'
alias zsh-reload-all='_zsh-reload-all'
# Deprecated: use 'dot shell reset'
alias zsh-reset='dot shell reset'
# Deprecated: use 'dot shell clean'
alias dot-clean-home='dot shell clean'
# Deprecated: use 'dot color-test'
alias dot-run-color-test='dot color-test'

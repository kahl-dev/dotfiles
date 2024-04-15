#!/bin/sh

alias ex='exit'

# Alises for developer Makefile
alias mi='if [ -f Makefile ] && grep -q "^install:" Makefile; then \
             make install; \
           else \
             echo "No Makefile found or no install command defined"; \
           fi'

alias mb='if [ -f Makefile ] && grep -q "^build:" Makefile; then \
             make build; \
           else \
             echo "No Makefile found or no build command defined"; \
           fi'

alias md='if [ -f Makefile ]; then \
             if grep -q "^dev:" Makefile; then \
               make dev; \
             elif grep -q "^develop:" Makefile; then \
               make develop; \
             else \
               echo "No dev or develop command defined in Makefile"; \
             fi; \
           else \
             echo "No Makefile found"; \
           fi'

if _exec_exists lazygit; then
  alias lg='lazygit'
fi

# Shows custom command list
alias custom_command_list="bat $DOTFILES/docs/Commands.md"
alias ccl="custom_command_list"

# ls, the common ones I use a lot shortened for rapid fire usage
alias l="ls -lFh"     #size,show type,human readable
alias la='ls -lAFh'   #long list,show almost all,show type,human readable
alias ll='ls -l'      #long list

if _exec_exists colorls; then
  alias l='colorls -lah --gs'
  alias la='colorls -lah --gs'
  alias ll='colorls -lh --gs'
fi

if _exec_exists neofetch; then
  alias info='neofetch'
fi

alias dotfiles='vim ~/.dotfiles'
alias nvimrc='vim ~/.config/nvim/'
alias zshrc='vim ${ZDOTDIR:-$HOME}/.zshrc'
alias zsh-update-plugins="find "$ZDOTDIR/plugins" -type d -exec test -e '{}/.git' ';' -print0 | xargs -I {} -0 git -C {} pull -q"

alias grep='grep --color'
alias sgrep='grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} '
# Grep all aliases
alias agrep='alias | grep'

alias t='tail -f'

# add wrappte to for man and cat to use tldr and bat
alias man="$DOTFILES/bin/man-wrapper-for-tldr.sh"
alias cat="$DOTFILES/bin/cat-wrapper-for-bat.sh"

# Command line head / tail shortcuts
alias help='man'



# alias cp='cp -i'
# alias mv='mv -i'
alias rm='rm -i'

if _exec_exists browser-sync; then
  alias bs='browser-sync'
fi

# Make zsh know about hosts already accessed by SSH
zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

# Theme and colors
alias theme='echo $BASE16_THEME'
alias base16color='curl -s https://gist.githubusercontent.com/HaleTom/89ffe32783f89f403bba96bd7bcd1263/raw/ | bash'

# Get my ip
alias myip="curl http://ipecho.net/plain; echo"

# alias j='z'
# alias f='zi'

# easier to read disk
alias df='df -h'     # human-readable sizes
alias free='free -m' # show sizes in MB

# get top process eating memory
alias psmem='ps auxf | sort -nr -k 4 | head -5'

# get top process eating cpu ##
alias pscpu='ps auxf | sort -nr -k 3 | head -5'

if _exec_exists gh; then

  # Directly check the output of `gh auth status` in the conditional
  if gh auth status 2>&1 | grep -q "You are not logged into any GitHub hosts"; then
    echo "You are not logged into any GitHub hosts. Initiating login..."
    gh auth login --web -h github.com
  fi

  if ! gh copilot > /dev/null 2>&1; then
    echo "gh copilot is not available, installing..."
    gh extension install github/gh-copilot --force
  fi

  eval "$(gh copilot alias -- zsh)"

  # Define functions
  function gh_copilot_shell_suggest {
      gh copilot suggest -t shell "$*"
  }
  function gh_copilot_gh_suggest {
      gh copilot suggest -t gh "$*"
  }
  function gh_copilot_git_suggest {
      gh copilot suggest -t git "$*"
  }

  # Set aliases
  alias '??'=gh_copilot_shell_suggest
  alias 'gh?'=gh_copilot_gh_suggest
  alias 'git?'=gh_copilot_git_suggest
fi

# Allow SSH tab completion for mosh hostnames
compdef mosh=ssh


case "$(uname -s)" in

Darwin)
	alias ls='ls -G'

  if _exec_exists colorls; then
	  alias ls='l'
  fi

  # confirm before overwriting something
  if _exec_exists trash; then
    alias rm='trash'
  fi

  # Add markdownreader app
  function marked() {
    if [ "$1" ]; then
        open -a "marked 2.app" "$1"
    else
        open -a "marked 2.app"
    fi
  }

  # Quick-Look a specified file
  function quick-look() {
    (( $# > 0 )) && qlmanage -p $* &>/dev/null &
  }

  # Open a specified man page in Preview app
  function man-preview() {
    # Don't let Preview.app steal focus if the man page doesn't exist
    man -w "$@" &>/dev/null && man -t "$@" | open -f -a Preview || man "$@"
  }
  compdef _man man-preview

  # Show/hide hidden files in the Finder
  alias showfiles="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
  alias hidefiles="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

  # Remove .DS_Store files recursively in a directory, default .
  function rmdsstore() {
    find "${@:-.}" -type f -name .DS_Store -delete
  }

  # Open the current directory in a Finder window
  alias ofd='open $PWD'

  # cd to the current Finder directory
  function cdf() {
    cd "$(pfd)"
  }
	;;

Linux)
	alias ls='ls --color=auto'

  if _exec_exists colorls; then
    alias ls='l'
  fi
	;;

CYGWIN* | MINGW32* | MSYS* | MINGW*)
	# echo 'MS Windows'
	;;
*)
	# echo 'Other OS'
	;;
esac


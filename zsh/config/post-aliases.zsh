#!/bin/sh

alias ex='exit'

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

alias dotfiles='vim ~/.dotfiles'
alias nvimrc='vim ~/.config/nvim/'
alias zshrc='vim ${ZDOTDIR:-$HOME}/.zshrc'
alias zsh-update-plugins="find "$ZDOTDIR/plugins" -type d -exec test -e '{}/.git' ';' -print0 | xargs -I {} -0 git -C {} pull -q"

alias grep='grep --color'
alias sgrep='grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} '
# Grep all aliases
alias agrep='alias | grep'

alias t='tail -f'

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

if _exec_exists github-copilot-cli; then
  # Add ??, git??, and gh? commands for github copilot clients
  # https://www.npmjs.com/package/@githubnext/github-copilot-cli
  eval "$(github-copilot-cli alias -- "$0")"
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


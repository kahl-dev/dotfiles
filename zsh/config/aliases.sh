#!/bin/sh

# ls, the common ones I use a lot shortened for rapid fire usage
alias l="ls -lFh"     #size,show type,human readable
alias la='ls -lAFh'   #long list,show almost all,show type,human readable
alias ll='ls -l'      #long list

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

# confirm before overwriting something
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Make zsh know about hosts already accessed by SSH
zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

# Theme and colors
alias theme='echo $BASE16_THEME'
alias base16color='curl -s https://gist.githubusercontent.com/HaleTom/89ffe32783f89f403bba96bd7bcd1263/raw/ | bash'

# Get my ip
alias myip="curl http://ipecho.net/plain; echo"

alias ryid='rm -Rf node_modules && yarn install && yarn dev'
alias ryib='rm -Rf node_modules && yarn install && yarn build'

# alias j='z'
# alias f='zi'

# easier to read disk
alias df='df -h'     # human-readable sizes
alias free='free -m' # show sizes in MB

# get top process eating memory
alias psmem='ps auxf | sort -nr -k 4 | head -5'

# get top process eating cpu ##
alias pscpu='ps auxf | sort -nr -k 3 | head -5'

case "$(uname -s)" in

Darwin)
	alias ls='ls -G'

  # Add markdownreader app
  alias marked='open -a "Marked 2"'
	;;

Linux)
	alias ls='ls --color=auto'
	;;

CYGWIN* | MINGW32* | MSYS* | MINGW*)
	# echo 'MS Windows'
	;;
*)
	# echo 'Other OS'
	;;
esac


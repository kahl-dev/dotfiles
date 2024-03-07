ZDOTDIR=$HOME/.config/zsh
DOTFILES=$HOME/.dotfiles

# Colors
COLOR_RED=$'\033[31;1m'
COLOR_CYAN=$'\033[0;36m'
COLOR_BLUE=$'\033[0;34m'
COLOR_YELLOW=$'\033[1;33m'
COLOR_OFF=$'\033[0m'

_exec_exists() {
	command -v "$1" >/dev/null 2>&1
}

_is_osx() {
	[[ $(uname -s) =~ "Darwin" ]] && return 0 || return 1
}

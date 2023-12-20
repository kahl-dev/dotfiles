#!/bin/bash

source $DOTFILES/scripts/config.sh
source $DOTFILES/scripts/should_run_check.sh

_symlink() {
	TYPE='Create'
	if [ -L "$2" ]; then
		rm "$2"
		TYPE='Overwrite'
	elif [ -e "$2" ]; then
		printf "${COLOR_YELLOW}$2 already exists as a file or directory${COLOR_OFF}\n"
		return
	fi
	printf "${COLOR_CYAN}$TYPE symlink $1 -> $2${COLOR_OFF}\n"
	ln -s "$1" "$2"
}

_copyfile() {
	TYPE='Copy'
	if [ -e "$2" ]; then
		if ! diff -q "$1" "$2" >/dev/null 2>&1; then
			printf "${COLOR_YELLOW}$2 already exists and is different. Moving to temporary directory...${COLOR_OFF}\n"
			temp_dir="$HOME/temp_dir"
			mkdir -p "$temp_dir"
			mv "$2" "$temp_dir"
		else
			printf "${COLOR_YELLOW}$2 already exists and is identical. Skipping...${COLOR_OFF}\n"
			return
		fi
		TYPE='Overwrite'
	fi
	printf "${COLOR_CYAN}$TYPE file $1 -> $2${COLOR_OFF}\n"
	cp "$1" "$2"
}

_createPath() {
	if [ ! -d "$1" ]; then
		printf "${COLOR_CYAN}Create path $1${COLOR_OFF}\n"
		mkdir -p "$1"
	fi
}

_removeSymlinkOrFile() {
	file_path="$1"
	temp_dir="$HOME/tmp_dir"

	if [ -L "$file_path" ]; then
		printf "${COLOR_CYAN}Removing symlink $file_path${COLOR_OFF}\n"
		rm "$file_path"
	elif [ -f "$file_path" ]; then
		printf "${COLOR_CYAN}Moving file $file_path to $temp_dir${COLOR_OFF}\n"
		mkdir -p "$temp_dir"
		mv "$file_path" "$temp_dir"
	else
		printf "${COLOR_RED}$file_path is neither a symlink nor a regular file${COLOR_OFF}\n"
	fi
}

_exec_exists() {
	command -v "$1" >/dev/null 2>&1
}

_is_raspberry() {
	_exec_exists raspi-config
}

_is_osx() {
	[[ $(uname -s) =~ "Darwin" ]] && return 0 || return 1
}

_is_linux() {
	[[ $(uname -s) =~ "Linux" ]] && return 0 || return 1
}

_is_path_exists() {
  if [ -e "$1" ]; then
    return 0  # Path exists
  else
    return 1  # Path does not exist
  fi
}

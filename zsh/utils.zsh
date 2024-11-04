#!/usr/bin/env zsh

# Check if a command exists
command_exists() {
	command -v "$1" >/dev/null 2>&1
# Fallback logic to ensure 'uname' works
ensure_uname() {
  if ! command_exists uname; then
    # Specify the fallback path to uname (adjust this path as needed)
    local fallback_uname="/usr/bin/uname"
    
    if [[ -x "$fallback_uname" ]]; then
      alias uname="$fallback_uname"
    else
      echo "uname not found and fallback not executable."
      return 1
    fi
  fi
}

# Check if the system is a Raspberry Pi
is_raspberry_pi() {
	command_exists raspi-config
}

# Check if the system is macOS
is_macos() {
  ensure_uname
  [[ "$(uname -s)" == "Darwin" ]]
}

# Check if the system is Linux
is_linux() {
  ensure_uname
  [[ "$(uname -s)" == "Linux" ]]
}

# Check if a file exists
file_exists() {
  [[ -f "$1" ]]
}

# Check if a folder exists
folder_exists() {
  [[ -d "$1" ]]
}

# Check if a path exists
path_exists() {
	[[ -e "$1" ]]
}

# Check if the script is running on an SSH client
is_ssh_client() {
  [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]
}

open_command() {
  local open_cmd

  # define the open command
  case "$OSTYPE" in
    darwin*)  open_cmd='open' ;;
    cygwin*)  open_cmd='cygstart' ;;
    linux*)   [[ "$(uname -r)" != *icrosoft* ]] && open_cmd='nohup xdg-open' || {
                open_cmd='cmd.exe /c start ""'
                [[ -e "$1" ]] && { 1="$(wslpath -w "${1:a}")" || return 1 }
              } ;;
    msys*)    open_cmd='start ""' ;;
    *)        echo "Platform $OSTYPE not supported"
              return 1
              ;;
  esac

  # If a URL is passed, $BROWSER might be set to a local browser within SSH.
  # See https://github.com/ohmyzsh/ohmyzsh/issues/11098
  if [[ -n "$BROWSER" && "$1" = (http|https)://* ]]; then
    "$BROWSER" "$@"
    return
  fi

  ${=open_cmd} "$@" &>/dev/null
}

# Prompt for user input (yes/no)
# Usage: prompt_user "Your question here" yes_action no_action
prompt_user() {
  local question=$1
  local yes_action=$2
  local no_action=$3

  echo "$question"
  select yn in "Yes" "No"; do
    case $yn in
      Yes)
        eval "$yes_action"
        break
        ;;
      No)
        eval "$no_action"
        break
        ;;
    esac
  done
}

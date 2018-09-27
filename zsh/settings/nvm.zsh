# Check if 'nvm' is a command in $PATH
nvm() {

  # Remove this function
  unfunction "$0"

  export NVM_DIR="$HOME/.nvm"
  export PATH=$NVM_DIR/versions/node/global/bin:$PATH
  export MANPATH=$NVM_DIR/versions/node/global/share/man:$MANPATH

  if [[ -f /usr/local/opt/nvm/nvm.sh ]]; then
    . /usr/local/opt/nvm/nvm.sh
    nvm "$@"
  elif [[ -f $NVM_DIR/nvm.sh ]]; then
    . $NVM_DIR/nvm.sh
    nvm "$@"
  fi

  if [[ -f /usr/local/share/bash-completion/bash_completion ]]; then
    . /usr/local/share/bash-completion/bash_completion
  elif [[ -f $NVM_DIR/bash_completion ]]; then
    . $NVM_DIR/bash_completion
  fi
}

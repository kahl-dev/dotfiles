lazynvm() {
  export NVM_DIR="$HOME/.nvm"
  export PATH=$NVM_DIR/versions/node/global/bin:$PATH
  export MANPATH=$NVM_DIR/versions/node/global/share/man:$MANPATH

  if [[ -f /usr/local/opt/nvm/nvm.sh ]]; then
    . /usr/local/opt/nvm/nvm.sh
  elif [[ -f $NVM_DIR/nvm.sh ]]; then
    . $NVM_DIR/nvm.sh
  fi
}

# Check if 'nvm' is a command in $PATH
nvm() {
  unfunction "$0"
  lazynvm()
  nvm "$@"
}

npm() {
  unfunction "$0"
  lazynvm()

  NODE_MODULES="${HOME}/.node_modules"
  PATH="$PATH:$NODE_MODULES/bin"

  # Unset manpath so we can inherit from /etc/manpath via the `manpath` command
  unset MANPATH
  export MANPATH="$NODE_MODULES/share/man:$(manpath)"

  npm "$@"
}

node() {
  unfunction "$0"
  lazynvm()
  node $@
}

npx() {
  unfunction "$0"
  lazynvm()
  npx $@
}

# nvm completion
. $(brew --prefix)/etc/bash_completion.d/nvm

# npm list without dependencies
alias npmLs="npm ls --depth=0 "$@" 2>/dev/null"
alias npmLsg="npm ls -g --depth=0 "$@" 2>/dev/null"

alias npmid='npm install -g yarn grunt prettier vue-cli tldr diff-so-fancy yo generator-alfred eslint eslint-plugin-vue'
alias npmida='npm install -g alfred-tyme alfred-bitly alfred-updater alfred-notifier alfred-polyglot alfred-fkill alfred-coolors alfred-npms alfred-hl'

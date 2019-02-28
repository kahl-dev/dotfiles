lazynvm() {
  if [[ -f /usr/local/opt/nvm/nvm.sh ]]; then
    source /usr/local/opt/nvm/nvm.sh
  elif [[ -f $(brew --prefix nvm)/nvm.sh ]]; then
    source $(brew --prefix nvm)/nvm.sh
  fi
}

MANPATH=$NVM_DIR/versions/node/global/share/man:$MANPATH
PATH=$NVM_DIR/versions/node/global/bin:$PATH
export NVM_DIR=$HOME/.nvm
node() { unfunction node npm npx && lazynvm && `whence -p node` $* }
npm() { unfunction node npm npx && lazynvm && `whence -p npm` $* }
npx() { unfunction node npm npx && lazynvm && `whence -p npx` $* }
nvm() { lazynvm && nvm $* }

# NODE_MODULES="${HOME}/.node_modules"
# PATH=$NODE_MODULES/bin:$PATH

# Unset manpath so we can inherit from /etc/manpath via the `manpath` command
# MANPATH=$NODE_MODULES/share/man:$MANPATH

# nvm completion
. $(brew --prefix)/etc/bash_completion.d/nvm

# if [ $(hostname) = "typo3-dev" ]; then
#   npm config set prefix $(nvm which 6)/../../
# else
#   npm config set prefix $(nvm which 11)/../../
# fi

# npm list without dependencies
alias npmLs="npm ls --depth=0 "$@" 2>/dev/null"
alias npmLsg="npm ls -g --depth=0 "$@" 2>/dev/null"

alias npmid='npm install -g yarn yarn-completions npm-check grunt prettier vue-cli tldr diff-so-fancy yo generator-alfred eslint eslint-plugin-vue serve'
alias npmida='npm install -g alfred-tyme alfred-bitly alfred-updater alfred-notifier alfred-polyglot alfred-fkill alfred-coolors alfred-hl'

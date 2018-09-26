export NVM_DIR="$HOME/.nvm"
export PATH=$NVM_DIR/versions/node/global/bin:$PATH
export MANPATH=$NVM_DIR/versions/node/global/share/man:$MANPATH
initNvm() {
  if [ "$(uname 2> /dev/null)" = "Darwin" ]; then
  . "/usr/local/opt/nvm/nvm.sh"
  else
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    nvm "${@}"
  fi
}

initNvmCompletion () {
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
}

# after_init+=(nvmInit)

alias loadnvm='initNvm > /dev/null && initNvmCompletion > /dev/null'
alias npmid='npm install -g yarn grunt prettier vue-cli tldr diff-so-fancy yo generator-alfred'
alias npmida='npm install -g alfred-tyme alfred-bitly alfred-updater alfred-notifier alfred-polyglot alfred-fkill alfred-coolors alfred-npms alfred-hl'

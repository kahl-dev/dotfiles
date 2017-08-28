export NVM_DIR="$HOME/.nvm"
export NVM_LAZY_LOAD=true
export NVM_AUTO_USE=true

plugins+=(zsh-nvm)

nvmInit() {
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
}

after_init+=(nvmInit)

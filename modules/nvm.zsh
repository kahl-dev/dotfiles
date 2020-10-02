# Zsh plugin for installing, updating and loading nvm
# https://github.com/lukechilds/zsh-nvm

export NVM_LAZY_LOAD=false
# export NVM_LAZY_LOAD_EXTRA_COMMANDS=('vim')
export NVM_AUTO_USE=true
export NVM_SYMLINK_CURRENT=true
export NVM_COMPLETION=true

function initNvm {
  [ ! -d "$HOME/.nvm/default-packages" ] && cp $DOTFILES/config/default-packages $HOME/.nvm/default-packages
}

zinit ice wait"2" lucid atload"initNvm"
zinit load lukechilds/zsh-nvm

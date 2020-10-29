# Zsh plugin for installing, updating and loading nvm
# https://github.com/lukechilds/zsh-nvm

export NVM_LAZY_LOAD=false
# export NVM_LAZY_LOAD_EXTRA_COMMANDS=('vim')
export NVM_AUTO_USE=true
export NVM_SYMLINK_CURRENT=false
export NVM_COMPLETION=true

function initNvm {
  [ ! -d "$HOME/.nvm/default-packages" ] && cp $DOTFILES/config/default-packages $HOME/.nvm/default-packages
  [ ! -d "$HOME/.nvm/default" ] && ln -sf $(nvm which default) "$HOME/.nvm/default"
  [ ! -d "$HOME/.nvm/latest" ] && ln -sf $(nvm which node) "$HOME/.nvm/latest"
  [[ -f "$HOME/.nvm/latest/lib/node_modules/yarn-completions/node_modules/tabtab/.completions/yarn.zsh" ]] && . "$HOME/.nvm/latest/lib/node_modules/yarn-completions/node_modules/tabtab/.completions/yarn.zsh"
}

zinit ice wait lucid atload"initNvm"
zinit load lukechilds/zsh-nvm

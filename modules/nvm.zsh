# Zsh plugin for installing, updating and loading nvm
# https://github.com/lukechilds/zsh-nvm

export NVM_LAZY_LOAD=false
# export NVM_LAZY_LOAD_EXTRA_COMMANDS=('vim')
export NVM_AUTO_USE=true
export NVM_SYMLINK_CURRENT=false
export NVM_COMPLETION=true

function initNvm {
  [ ! -d "$HOME/.nvm/default-packages" ] && cp $DOTFILES/config/default-packages $HOME/.nvm/default-packages
  export NVM_STABLE=~/.nvm/versions/node/$($(nvm which stable) --version)
  export COC_NODE_PATH=$NVM_STABLE/bin/node
  [[ -f "$NVM_STABLE/lib/node_modules/yarn-completions/node_modules/tabtab/.completions/yarn.zsh" ]] && . "$NVM_STABLE/lib/node_modules/yarn-completions/node_modules/tabtab/.completions/yarn.zsh"
}

zinit ice wait lucid atload"initNvm"
zinit load lukechilds/zsh-nvm

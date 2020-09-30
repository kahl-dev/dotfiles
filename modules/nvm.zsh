# Zsh plugin for installing, updating and loading nvm
# https://github.com/lukechilds/zsh-nvm

export NVM_LAZY_LOAD=false
# export NVM_LAZY_LOAD_EXTRA_COMMANDS=('vim')
export NVM_AUTO_USE=true
export NVM_SYMLINK_CURRENT=true

zinit ice wait"2" lucid
zinit load lukechilds/zsh-nvm

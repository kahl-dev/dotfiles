# lazynvm() {
source $(brew --prefix nvm)/nvm.sh
# }

export NVM_DIR=$HOME/.nvm
MANPATH=$NVM_DIR/versions/node/global/share/man:$MANPATH

# node() { unfunction node npm npx && lazynvm && `whence -p node` $* }
# npm() { unfunction node npm npx && lazynvm && `whence -p npm` $* }
# npx() { unfunction node npm npx && lazynvm && `whence -p npx` $* }
# nvm() { lazynvm && nvm $* }

# nvm completion
. $(brew --prefix)/etc/bash_completion.d/nvm
# source $(brew --prefix nvm)/nvm.sh

# Set default nvm alias as global npm prefix
# to prevent loading nvm on shell init
if [[ -f ~/.nvm/alias/default ]]; then
  cat ~/.nvm/alias/default | while read line
  do
    VERSION="$line"
    NPM_CONFIG_PREFIX=~/.nvm/versions/node/$VERSION
    PATH=$NPM_CONFIG_PREFIX/bin:$PATH
  done
fi

# npm list without dependencies
alias npmLs="npm ls --depth=0 "$@" 2>/dev/null"
alias npmLsg="npm ls -g --depth=0 "$@" 2>/dev/null"

alias npmid='npm install -g yarn yarn-completions npm-check grunt prettier vue-cli tldr diff-so-fancy yo generator-alfred babel-eslint eslint eslint-config-prettier eslint-plugin-html eslint-plugin-prettier eslint-plugin-vue serve inspect-process serverless'
alias npmida='npm install -g alfred-tyme alfred-bitly alfred-updater alfred-notifier alfred-polyglot alfred-fkill alfred-coolors alfred-hl alfred-tabs-improved'

# place this after nvm initialization!
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

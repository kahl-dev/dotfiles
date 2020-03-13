export NVM_DIR="$HOME/.nvm"
export NVM_LAZY_LOAD=true
export NVM_AUTO_USE=true
plugins+=(zsh-nvm)

# npm list without dependencies
alias npmLs="npm ls --depth=0 "$@" 2>/dev/null"
alias npmLsg="npm ls -g --depth=0 "$@" 2>/dev/null"

alias npmid='npm install -g yarn yarn-completions npm-check grunt prettier vue-cli tldr diff-so-fancy yo generator-alfred babel-eslint eslint eslint-config-prettier eslint-plugin-html eslint-plugin-prettier eslint-plugin-vue serve inspect-process serverless'
alias npmida='npm install -g alfred-tyme alfred-bitly alfred-updater alfred-notifier alfred-polyglot alfred-fkill alfred-coolors alfred-hl alfred-tabs-improved'

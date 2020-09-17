# @TODO try out
# Better completion for npm
# Doc: https://github.com/lukechilds/zsh-better-npm-completion
zinit ice wait"2" lucid
zinit load lukechilds/zsh-better-npm-completion

# npm list without dependencies
alias npmLs="npm ls --depth=0 "$@" 2>/dev/null"
alias npmLsg="npm ls -g --depth=0 "$@" 2>/dev/null"

alias npmid='npm install -g yarn yarn-completions npm-check grunt prettier vue-cli tldr diff-so-fancy yo generator-alfred babel-eslint eslint eslint-config-prettier eslint-plugin-html eslint-plugin-prettier eslint-plugin-vue serve inspect-process serverless browser-sync'
alias npmida='npm install -g alfred-updater alfred-notifier alfred-polyglot'

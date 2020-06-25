# npm list without dependencies
alias npmLs="npm ls --depth=0 "$@" 2>/dev/null"
alias npmLsg="npm ls -g --depth=0 "$@" 2>/dev/null"

alias npmid='ASDF_SKIP_RESHIM=1 npm install -g yarn yarn-completions npm-check grunt prettier vue-cli tldr diff-so-fancy yo generator-alfred babel-eslint eslint eslint-config-prettier eslint-plugin-html eslint-plugin-prettier eslint-plugin-vue serve inspect-process serverless && asdf reshim nodejs'
alias npmida='ASDF_SKIP_RESHIM=1 npm install -g alfred-updater alfred-notifier alfred-polyglot && asdf reshim nodejs'

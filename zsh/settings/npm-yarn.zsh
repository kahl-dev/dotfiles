npm() {

  # Remove this function
  unfunction "$0"

  NODE_MODULES="${HOME}/.node_modules"
  PATH="$PATH:$NODE_MODULES/bin"

  # Unset manpath so we can inherit from /etc/manpath via the `manpath` command
  unset MANPATH
  export MANPATH="$NODE_MODULES/share/man:$(manpath)"

  source $ZSH/plugins/npm/npm.plugin.zsh
  source $ZSH_CUSTOM/plugins/zsh-better-npm-completion/zsh-better-npm-completion.plugin.zsh

  nvm "$@"
}

# npm list without dependencies
alias npmLs="npm ls --depth=0 "$@" 2>/dev/null"
alias npmLsg="npm ls -g --depth=0 "$@" 2>/dev/null"

alias npmid='npm install -g yarn grunt prettier vue-cli tldr diff-so-fancy yo generator-alfred'
alias npmida='npm install -g alfred-tyme alfred-bitly alfred-updater alfred-notifier alfred-polyglot alfred-fkill alfred-coolors alfred-npms alfred-hl'

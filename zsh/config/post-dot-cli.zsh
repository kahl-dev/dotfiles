# alias dot-cli='node $DOTFILES/bin/dot-cli/src/index.mjs'

if _exec_exists "dot-cli"; then
  alias dc='dot-cli'
  zsh_add_completion "dot-cli" true
fi






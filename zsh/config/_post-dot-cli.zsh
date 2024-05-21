! _is_path_exists "$DOTFILES/bin/dot-cli/node_modules/" && cd "$DOTFILES/bin/dot-cli" && pnpm install

alias dot-cli="node $DOTFILES/bin/dot-cli/src/index.mjs"
alias dc="dot-cli"
zsh_add_completion "dot-cli" true







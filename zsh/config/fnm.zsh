# if [ -d "$DOTFILES/bin/fnm" ]; then
#   export PATH=$DOTFILES/bin/fnm:$PATH
#   eval "`fnm env`"
# fi

# if ! _exec_exists fnm; then
#   curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$DOTFILES/bin/fnm" --skip-shell
# fi

if _exec_exists fnm; then
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"

  if [ ! -L "$FNM_DIR/aliases/lts-latest" ]; then
    fnm install --lts
    fnm use lts-latest
    cat $DOTFILES/config/default-packages | xargs npm install -g
  fi
  export NODE_PATH=$FNM_DIR/aliases/lts-latest
  [[ -f "$NODE_PATH/lib/node_modules/yarn-completions/node_modules/tabtab/.completions/yarn.zsh" ]] && . "$NODE_PATH/lib/node_modules/yarn-completions/node_modules/tabtab/.completions/yarn.zsh"
fi

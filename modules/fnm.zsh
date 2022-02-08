if _not_exists fnm; then
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$DOTFILES/bin/fnm" --skip-shell
fi

if _exists fnm; then
  export FNM_DIR="$DOTFILES/bin/fnm"

  if [ ! -d "$FNM_DIR/aliases/lts-latest" ]; then
    fnm install --lts
    cat $DOTFILES/config/default-packages | xargs npm install -g
  fi
  export NODE_PATH=$FNM_DIR/aliases/lts-latest
  [[ -f "$NODE_PATH/lib/node_modules/yarn-completions/node_modules/tabtab/.completions/yarn.zsh" ]] && . "$NODE_PATH/lib/node_modules/yarn-completions/node_modules/tabtab/.completions/yarn.zsh"

  plugins+=(fnm)
  eval "$(fnm env --use-on-cd)"
fi

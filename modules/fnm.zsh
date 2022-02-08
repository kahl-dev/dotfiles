if _not_exists fnm; then
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$DOTFILES/bin/fnm" --skip-shell
fi

if _exists fnm; then
  export NODE_PATH=$FNM_DIR/aliases/latest
  [[ -f "$NODE_PATH/lib/node_modules/yarn-completions/node_modules/tabtab/.completions/yarn.zsh" ]] && . "$NODE_PATH/lib/node_modules/yarn-completions/node_modules/tabtab/.completions/yarn.zsh"

  plugins+=(fnm)

  find-up () {
    path=$(pwd)
    while [[ "$path" != "" && ! -e "$path/$1" ]]; do
        path=${path%/*}
    done
    echo "$path"
  }

  autoload -U add-zsh-hook

  load-nvmrc() {
    NVM_PATH=$(find-up .nvmrc | tr -d '[:space:]')
    [ ! $NVM_PATH ] && return
    DEFAULT_NODE_VERSION=`cat $NVM_PATH/.nvmrc`
    if [[ -f .nvmrc && -r .nvmrc ]]; then
      fnm use
    elif [[ `node -v` != $DEFAULT_NODE_VERSION ]]; then
      echo Reverting to node from "`node -v`" to "$DEFAULT_NODE_VERSION"
      fnm use $DEFAULT_NODE_VERSION
      return
    fi
  }

  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
fi

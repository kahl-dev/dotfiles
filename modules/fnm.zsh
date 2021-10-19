function initFnm() {
  [ ! -d "$HOME/.fnm" ] && curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.fnm" --skip-shell


  export PATH=$HOME/.fnm:$PATH
  eval "`fnm env`"

  export NODE_STABLE=$FNM_DIR/aliases/latest
  export COC_NODE_PATH=$NODE_STABLE
  [[ -f "$NODE_STABLE/lib/node_modules/yarn-completions/node_modules/tabtab/.completions/yarn.zsh" ]] && . "$NODE_STABLE/lib/node_modules/yarn-completions/node_modules/tabtab/.completions/yarn.zsh"

  if [ ! -f "$HOME/.config/zsh/completions/_fnm" ]; then
    mkdir -p $HOME/.config/zsh/completions
    touch $HOME/.config/zsh/completions/_fnm
    fnm completions --shell=zsh > $HOME/.config/zsh/completions/_fnm
  fi
  zinit fpath -f $HOME/.config/zsh/completions/_fnm

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
}

zinit lucid atinit'initFnm' nocd for /dev/null

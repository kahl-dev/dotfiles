export EDITOR="vim"
export VISUAL="vim"

alias vi='vim'

if _exists nvim; then
  export EDITOR="vim"
  export VISUAL="vim"

  alias vim='nvim'
  
  ln -sf ~/.vim/nvimrc ~/.config/nvim/init.vim
else
  function initVim {
    export VIMRUNTIME="$ZINIT[PLUGINS_DIR]/vim---vim/runtime"
  }

  zinit ice wait lucid as"program" atclone"rm -f src/auto/config.cache; \
    ./configure --prefix=$ZPFX" atpull"%atclone" \
    make"all install" pick"$ZPFX/bin/vim"
  zinit light vim/vim
fi

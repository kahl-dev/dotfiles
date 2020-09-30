export EDITOR="vim"
export VISUAL="vim"

alias vi='vim'

function initVim {
    export VIMRUNTIME="$ZINIT[PLUGINS_DIR]/vim---vim/runtime"
}

zinit ice as"program" atload"initVim" atclone"rm -f src/auto/config.cache; ./configure" \
    atpull"%atclone" make pick"src/vim"
zinit light vim/vim

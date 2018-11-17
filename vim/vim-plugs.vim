" https://github.com/junegunn/vim-plug
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
call plug#begin('~/.vim/plugged')

" Snippet & Autocompletion {{{

Plug 'Valloric/YouCompleteMe', { 'on': [], 'do': './install.py --js-completer' }
command! Ycm call plug#load('YouCompleteMe') | call youcompleteme#Enable() | YcmCompleter

" }}}

call plug#end()

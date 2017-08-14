" https://github.com/junegunn/vim-plug
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
call plug#begin('~/.vim/plugged')

" Styling {{{

Plug 'altercation/vim-colors-solarized'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'yggdroot/indentline'
Plug 'editorconfig/editorconfig-vim'
Plug 'ryanoasis/vim-devicons'

" }}}
" Search {{{

Plug 'mileszs/ack.vim'
Plug 'scrooloose/nerdtree', { 'on':  ['NERDTreeToggle', 'NERDTreeFind'] }
Plug 'ctrlpvim/ctrlp.vim'

" }}}
" Language syntax & highlighting {{{

Plug 'sheerun/vim-polyglot'
Plug 'scrooloose/syntastic'
Plug 'marijnh/tern_for_vim',
  \ { 'do': 'cd ~/.vim/plugged/tern_for_vim && npm install',
  \ 'autoload': { 'filetypes': ['javascript'] } }

Plug 'mitermayer/vim-prettier', {
	\ 'do': 'npm install',
	\ 'for': ['javascript', 'javascript.jxa','css', 'scss'] }

" }}}
" Git {{{

Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

" }}}
" Helper {{{

Plug 'andrewradev/switch.vim'
Plug 'gioele/vim-autoswap'
Plug 'Raimondi/delimitMate'
Plug 'bronson/vim-trailing-whitespace'
Plug 'mattn/emmet-vim'
Plug 'christoomey/vim-tmux-navigator'
Plug 'michaeljsmith/vim-indent-object'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-eunuch'
Plug 'sjl/gundo.vim'

" }}}
" Snippet & Autocompletion {{{

Plug 'SirVer/ultisnips'
Plug 'valloric/youCompleteMe', { 'do': './install.py --tern-completer' }

" }}}

call plug#end()

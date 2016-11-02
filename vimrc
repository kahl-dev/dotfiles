" Colors {{{
syntax enable               " enable syntax processing
" }}}

" Spaces & Tabs {{{
set tabstop=4               " number of visual spaces per TAB
set softtabstop=4           " number of spaces in tab when editing
set expandtab               " tabs are spaces
" }}}

" UI Config {{{
set number                  " show line numbers
set cursorline              " highlight current line
" }}}

" Movement {{{
" move vertically by visual line
nnoremap j gj
nnoremap k gk

" move to beginning/end of line
nnoremap B ^
nnoremap E $
" }}}

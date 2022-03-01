" Doc: https://github.com/zhou13/vim-easyescape/
Plug 'zhou13/vim-easyescape'

let g:easyescape_chars = { "j": 1, "k": 1 }
let g:easyescape_timeout = 100
cnoremap jk <ESC>
cnoremap kj <ESC>

" jk | Escaping!
" inoremap jk <Esc>
" xnoremap jk <Esc>
" cnoremap jk <C-c>

" autocmd FileType text,markdown call setbufvar(bufnr("%"), 'easyescape_disable', 1)

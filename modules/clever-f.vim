" clever-f.vim extends f, F, t and T mappings for more convenience.
" Doc: https://github.com/rhysd/clever-f.vim
Plug 'rhysd/clever-f.vim'

let g:clever_f_across_no_line    = 1
let g:clever_f_fix_key_direction = 1
map ; <Plug>(clever-f-repeat-forward)
map , <Plug>(clever-f-repeat-back)

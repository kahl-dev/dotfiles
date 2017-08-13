" Syntastic
let g:airline#extensions#syntastic#enabled = 1
let g:syntastic_javascript_checkers = ['prettier']
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 0
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_auto_jump = 0
hi SpellBad term=reverse ctermbg=darkgreen

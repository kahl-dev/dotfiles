" This (neo)vim plugin makes scrolling nice and smooth.
" Doc: https://github.com/psliwka/vim-smoothie
Plug 'psliwka/vim-smoothie'

let g:smoothie_no_default_mappings = 1
silent! nmap <unique> <C-D>      <Plug>(SmoothieDownwards)
silent! nmap <unique> <C-U>      <Plug>(SmoothieUpwards)

" Smooth scroll
" Doc: https://github.com/psliwka/vim-smoothie

if &loadplugins
  if has('packages')

    packadd! vim-smoothie

  endif
endif

let g:smoothie_no_default_mappings = 1
silent! nmap <unique> <C-D>      <Plug>(SmoothieDownwards)
silent! nmap <unique> <C-U>      <Plug>(SmoothieUpwards)

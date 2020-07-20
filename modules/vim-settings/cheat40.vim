" https://github.com/lifepillar/vim-cheat40

if &loadplugins
  if has('packages')
    packadd! vim-cheat40
  endif
endif

let g:cheat40_use_default = 0
nmap <unique> <leader>ß :<c-u>Cheat40<cr>

if executable('ag')
  " bind K to grep word under cursor
  nnoremap K :grep! "\b<C-R><C-W>\b"<CR>:cw<CR>

  " bind \ (backward slash) to grep shortcut "
  command! -nargs=+ -complete=file Ag silent! grep! <args>|cwindow|redraw!
  nnoremap \ :Ag<space>
endif

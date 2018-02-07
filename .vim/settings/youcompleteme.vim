augroup load_ycm
  autocmd!
  autocmd CursorHold, CursorHoldI * :packadd YouCompleteMe
                                \ | autocmd! load_ycm
augroup END

nnoremap <leader>tt :YcmCompleter GoTo<CR>
nnoremap <leader>tr :YcmCompleter RefactorRename 


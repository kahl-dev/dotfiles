" CtrlP
" https://robots.thoughtbot.com/faster-grepping-in-vim
" http://vimawesome.com/plugin/ctrlp-vim-red
if executable('ag')
  " Use ag over grep "
  set grepprg=ag\ --nogroup\ --nocolor\ --column

  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore "
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

  " ag is fast enough that CtrlP doesn't need to cache "
  let g:ctrlp_use_caching = 0

  let g:ctrlp_match_window = 'bottom,order:ttb'
  let g:ctrlp_switch_buffer = 0
  let g:ctrlp_working_path_mode = 0
  let g:ctrlp_follow_symlinks = 1
  let g:ctrlp_max_files = 0
  let g:ctrlp_max_depth = 40
  let g:ctrlp_max_height = 40

  nnoremap <leader>b :CtrlPBuffer<CR>
endif

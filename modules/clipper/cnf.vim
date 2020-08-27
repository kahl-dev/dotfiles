" Add the ability to send yank text back to home system
" Doc: https://github.com/wincent/clipper

if $SSH_CLIENT
  nnoremap <leader>y :call system('nc -N 127.0.0.1 8377', @0)<CR>
  if exists('##TextYankPost')
    augroup Clipper
      autocmd!
      autocmd TextYankPost * call system('nc -N 127.0.0.1 8377', @0)
    augroup END
  endif
endif

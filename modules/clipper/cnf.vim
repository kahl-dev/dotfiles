" Add the ability to send yank text back to home system
" Doc: https://github.com/wincent/clipper

nnoremap <leader>y :call system('nc -N 127.0.0.1 8377', @0)<CR>

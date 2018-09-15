if executable('fzf')
" FZF {{{

execute 'set rtp+='.fnamemodify(systemlist('greadlink -f $(which fzf)')[0], ':h:h')

nnoremap <silent> <C-f>f :FZF -m<cr>
nnoremap <silent> <C-f>g :GFiles<cr>
nnoremap <silent> <C-f>s :GFiles?<cr>
nnoremap <silent> <C-f>b :Buffers<cr>
nnoremap <silent> <C-f>l :Lines<cr>
nnoremap <silent> <C-f>h :History<cr>
nnoremap <silent> <C-f>u :Snippets<cr>
nnoremap <silent> <C-f>c :Commands<cr>
nnoremap <silent> <C-f>h :Helptags<cr>

" Augmenting Ag command using fzf#vim#with_preview function
" :Ag  - Start fzf with hidden preview window that can be enabled with '?' key
" :Ag! - Start fzf in fullscreen and display the preview window above"
command! -bang -nargs=* Ag
  \ call fzf#vim#ag(<q-args>,
  \                 <bang>0 ? fzf#vim#with_preview('up:60%')
  \                         : fzf#vim#with_preview('right:50%:hidden', '?'),
  \                 <bang>0)

" }}}
endif

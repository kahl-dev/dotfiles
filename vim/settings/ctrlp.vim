if executable('fzf')
" FZF {{{

set rtp+=/usr/local/opt/fzf

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
else
" CtrlP {{{

" PyMatcher for CtrlP
if !has('python') && !has('python3')
  echo 'In order to use pymatcher plugin, you need +python compiled vim'
else
  let g:ctrlp_match_func = { 'match': 'pymatcher#PyMatch' }
endif

" Set delay to prevent extra search
let g:ctrlp_lazy_update = 350

" Do not clear filenames cache, to improve CtrlP startup
" You can manualy clear it by <F5>
let g:ctrlp_clear_cache_on_exit = 0

" ag is fast enough that CtrlP doesn't need to cache "
let g:ctrlp_use_caching = 0

let g:ctrlp_match_window = 'bottom,order:ttb'
let g:ctrlp_switch_buffer = 0
let g:ctrlp_working_path_mode = 0
let g:ctrlp_follow_symlinks = 1
let g:ctrlp_max_files = 0
let g:ctrlp_max_depth = 40
let g:ctrlp_max_height = 40

" If ag is available use it as filename list generator instead of 'find'
if executable("ag")
  set grepprg=ag\ --nogroup\ --nocolor
  let g:ctrlp_user_command = 'ag %s -i --nocolor --nogroup --ignore ''.git'' --ignore ''.DS_Store'' --ignore ''node_modules'' --hidden -g ""'
endif

nnoremap <leader>b :CtrlPBuffer<CR>
nnoremap <Leader>m :CtrlPModified<CR>

" }}}
endif

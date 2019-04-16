if executable('fzf')
" FZF {{{

if has("mac")
  set rtp+=/usr/local/opt/fzf
elseif has("unix")
  execute 'set rtp+='.fnamemodify(systemlist('greadlink -f $(which fzf)')[0], ':h:h')
endif

let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" Likewise, Files command with preview window
command! -bang -nargs=? -complete=dir Files
  \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

nnoremap <silent> <C-f>f :Files<cr>
nnoremap <silent> <C-f>b :Buffers<cr>
nnoremap <silent> <C-f>l :Lines<cr>
nnoremap <silent> <C-f>h :FZFMru<cr>
nnoremap <silent> <C-f>t :Filetypes<cr>

nnoremap <silent> <C-g>f :GFiles<cr>
nnoremap <silent> <C-g>b :BCommits<cr>
nnoremap <silent> <C-g>c :Commits<cr>
nnoremap <silent> <C-f>s :GFiles?<cr>

nnoremap <silent> <C-f>a :Ag!<cr>
nnoremap <silent> <C-f>r :Rg<cr>

command! FZFMru call fzf#run({
\ 'source':  reverse(s:all_files()),
\ 'sink':    'edit',
\ 'options': '-m -x +s',
\ 'down':    '40%' })

function! s:all_files()
  return extend(
  \ filter(copy(v:oldfiles),
  \        "v:val !~ 'fugitive:\\|NERD_tree\\|^/tmp/\\|.git/'"),
  \ map(filter(range(1, bufnr('$')), 'buflisted(v:val)'), 'bufname(v:val)'))
endfunction

" }}}

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

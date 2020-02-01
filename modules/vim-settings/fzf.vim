if executable('fzf')

  if has("mac")
    set rtp+=/usr/local/opt/fzf
  elseif has("unix")
    set rtp+=/home/kahl/.linuxbrew/opt/fzf
  endif

  let g:fzf_action = {
    \ 'ctrl-t': 'tab split',
    \ 'ctrl-x': 'split',
    \ 'ctrl-v': 'vsplit' }

  " Likewise, Files command with preview window
  command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

  nnoremap <silent> <leader>ff :Files<cr>
  nnoremap <silent> <leader>fb :Buffers<cr>
  nnoremap <silent> <leader>fl :Lines<cr>
  nnoremap <silent> <leader>fh :FZFMru<cr>
  nnoremap <silent> <leader>ft :Filetypes<cr>

  nnoremap <silent> <leader>gf :GFiles<cr>
  nnoremap <silent> <leader>gb :BCommits<cr>
  nnoremap <silent> <leader>gc :Commits<cr>
  nnoremap <silent> <leader>gs :GFiles?<cr>

  nnoremap <silent> <leader>fa :Ag!<cr>
  nnoremap <silent> <leader>fr :Rg<cr>

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


  " Augmenting Ag command using fzf#vim#with_preview function
  " :Ag  - Start fzf with hidden preview window that can be enabled with '?' key
  " :Ag! - Start fzf in fullscreen and display the preview window above"
  command! -bang -nargs=* Ag
    \ call fzf#vim#ag(<q-args>,
    \                 <bang>0 ? fzf#vim#with_preview('up:60%')
    \                         : fzf#vim#with_preview('right:50%:hidden', '?'),
    \                 <bang>0)


  command! -nargs=* -complete=dir Cd call fzf#run(fzf#wrap(
    \ {'source': 'find '.(empty(<f-args>) ? '.' : <f-args>).' -type d',
    \  'sink': 'cd'}))

endif

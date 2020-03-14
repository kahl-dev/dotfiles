if executable('fzf')

  if has("mac")
    set rtp+=/usr/local/opt/fzf
  elseif has("unix")
    set rtp+=/home/kahl/.linuxbrew/opt/fzf
  endif

  let g:fzf_action = {
    \ 'ctrl-x': 'split',
    \ 'ctrl-v': 'vsplit' }
  
  " Files with preview
  command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'options': ['--layout=reverse', '--info=inline']}), <bang>0)

  " Ripgrep with preview
  command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
  \   fzf#vim#with_preview(), <bang>0)

  " Advanced ripgrep integration (No Fuzzy)
  function! RipgrepFzf(query, fullscreen)
    let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case %s || true'
    let initial_command = printf(command_fmt, shellescape(a:query))
    let reload_command = printf(command_fmt, '{q}')
    let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
    call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
  endfunction

  command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)

  " Search all files
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

  nnoremap <silent> <leader>ff :Files<cr>
  nnoremap <silent> <leader>fb :Buffers<cr>
  nnoremap <silent> <leader>fl :Lines<cr>
  nnoremap <silent> <leader>fh :FZFMru<cr>
  nnoremap <silent> <leader>ft :Filetypes<cr>
  nnoremap <silent> <leader>fm :Marks<cr>

  nnoremap <silent> <leader>gf :GFiles<cr>
  nnoremap <silent> <leader>gb :BCommits<cr>
  nnoremap <silent> <leader>gc :Commits<cr>
  nnoremap <silent> <leader>gs :GFiles?<cr>

  nnoremap <silent> <leader>fr :Rg<cr>

endif

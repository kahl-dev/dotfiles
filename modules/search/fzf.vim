if executable('fzf')
  set rtp+=~/.fzf
  let g:fzf_action = {
    \ 'ctrl-x': 'split',
    \ 'ctrl-v': 'vsplit' }

  let g:fzf_preview_window = 'top:50%'
  " See `man fzf-tmux` for available options
  " if exists('$TMUX')
  "   let g:fzf_layout = { 'tmux': '-p90%,60%' }
  " else
    let g:fzf_layout = { 'window': { 'width': 0.95, 'height': 0.95 } }
  " endif
  
  " [[B]Commits] Customize the options used by 'git log':
  let g:fzf_commits_log_options = '--graph --color=always --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset"'
  
  " Files with preview
  " command! -bang -nargs=? -complete=dir Files
  "   \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'options': ['--layout=reverse', '--info=inline']}), <bang>0)

  command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, {'options': ['--layout=reverse', '--info=inline', '--preview', '~/.vim/pack/bundle/opt/fzf.vim/bin/preview.sh {}']}, <bang>0)

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

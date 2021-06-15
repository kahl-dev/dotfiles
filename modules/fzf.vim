" Fuzzy search in vim
" Doc: https://github.com/junegunn/fzf.vim
" Doc: https://github.com/junegunn/fzf
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
" Plug /home/kahl/.zinit/polaris/bin/fzf
Plug 'junegunn/fzf.vim'

" Manage branches and tags with fzf.
" Doc: https://github.com/stsewd/fzf-checkout.vim
Plug 'stsewd/fzf-checkout.vim'

let g:fzf_checkout_git_options = '--sort=-committerdate'

let g:fzf_action = {
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" let g:fzf_commits_log_options = '--exact'
" let g:fzf_preview_window = ''
let g:fzf_command_prefix = 'Fzf'

" let g:fzf_preview_window = 'top:50%'
" See `man fzf-tmux` for available options
" if exists('$TMUX')
  " let g:fzf_prefer_tmux = 1
  " let g:fzf_layout = { 'tmux': '-p90%,60%' }
" else
  let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6, 'highlight': 'Todo', 'border': 'sharp' } }
  " let g:fzf_layout = { 'down': '~60%' }
" endif


nnoremap <silent> <leader>ff :FzfFiles<cr>
nnoremap <silent> <leader>fb :FzfBuffers<cr>
nnoremap <silent> <leader>fl :FzfLines<cr>
nnoremap <silent> <leader>ft :FzfFiletypes<cr>
nnoremap <silent> <leader>fm :FzfMarks<cr>

nnoremap <silent> <leader>gf :FzfGFiles?<cr>
nnoremap <silent> <leader>gcb :FzfBCommits<cr>
nnoremap <silent> <leader>gcc :FzfCommits<cr>
nnoremap <silent> <leader>gb :FzfGBranches<cr>

" nnoremap <silent> <leader>fr :FzfRg<cr>
nnoremap <silent> <leader>fr :RipgrepFzf<cr>

function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)

function! s:list_buffers()
  redir => list
  silent ls
  redir END
  return split(list, "\n")
endfunction

function! s:delete_buffers(lines)
  execute 'bwipeout' join(map(a:lines, {_, line -> split(line)[0]}))
endfunction

command! BD call fzf#run(fzf#wrap({
  \ 'source': s:list_buffers(),
  \ 'sink*': { lines -> s:delete_buffers(lines) },
  \ 'options': '--multi --reverse --bind ctrl-a:select-all+accept'
\ }))

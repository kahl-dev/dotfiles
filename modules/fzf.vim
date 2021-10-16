" Fuzzy search in vim
" Doc: https://github.com/junegunn/fzf.vim
" Plug '~/.zinit/plugins/junegunn---fzf/'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" Manage branches and tags with fzf.
" Doc: https://github.com/stsewd/fzf-checkout.vim
Plug 'stsewd/fzf-checkout.vim'

let g:fzf_checkout_git_options = '--sort=-committerdate'

let g:fzf_action = {
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" let g:fzf_commits_log_options = '--exact'
let g:fzf_command_prefix = 'Fzf'

let g:fzf_preview_window = ['down:60%']
" See `man fzf-tmux` for available options
if exists('$TMUX')
  let g:fzf_prefer_tmux = 1
  let g:fzf_layout = { 'tmux': '-p90%,60%' }
else
  let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6, 'highlight': 'Todo', 'border': 'sharp' } }
endif

nnoremap <silent> <leader>ff :FzfFiles<cr>
nnoremap <silent> <leader>fb :FzfBuffers<cr>
nnoremap <silent> <leader>fl :FzfLines<cr>
nnoremap <silent> <leader>ft :FzfFiletypes<cr>
nnoremap <silent> <leader>fm :FzfMarks<cr>

nnoremap <silent> <leader>gf :FzfGFiles?<cr>
nnoremap <silent> <leader>gcb :FzfBCommits<cr>
nnoremap <silent> <leader>gcc :FzfCommits<cr>
nnoremap <silent> <leader>gb :FzfGBranches<cr>

nnoremap <silent> <leader>fr :FzfRg<cr>

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

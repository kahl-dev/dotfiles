" Fuzzy search in vim
" Doc: https://github.com/junegunn/fzf.vim
" Doc: https://github.com/junegunn/fzf
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Manage branches and tags with fzf.
" Doc: https://github.com/stsewd/fzf-checkout.vim
Plug 'stsewd/fzf-checkout.vim'

" set rtp+="$ZINIT[PLUGINS_DIR]/fzf/bin/fzf"
let g:fzf_action = {
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" let g:fzf_preview_window = 'top:50%'
" See `man fzf-tmux` for available options
" if exists('$TMUX')
  " let g:fzf_prefer_tmux = 1
  " let g:fzf_layout = { 'tmux': '-p90%,60%' }
" else
  let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6, 'highlight': 'Todo', 'border': 'sharp' } }
  " let g:fzf_layout = { 'down': '~60%' }
" endif

nnoremap <silent> <leader>ff :Files<cr>
nnoremap <silent> <leader>fb :Buffers<cr>
nnoremap <silent> <leader>fl :Lines<cr>
nnoremap <silent> <leader>fh :FZFMru<cr>
nnoremap <silent> <leader>ft :Filetypes<cr>
nnoremap <silent> <leader>fm :Marks<cr>

nnoremap <silent> <leader>gf :GFiles?<cr>
nnoremap <silent> <leader>gb :BCommits<cr>
" nnoremap <silent> <leader>gc :Commits<cr>
nnoremap <silent> <leader>gc :GCheckout<cr>

nnoremap <silent> <leader>fr :Rg<cr>

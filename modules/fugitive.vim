" Fugitive is the premier Vim plugin for Git. Or maybe it's the premier
" Git plugin for Vim?
" Doc: https://github.com/tpope/vim-fugitive
Plug 'tpope/vim-fugitive'

set diffopt+=vertical

nmap <leader>gr :diffget //3<CR>
nmap <leader>gl :diffget //2<CR>
nmap <leader>gs :G<CR>

" Fugitive is the premier Vim plugin for Git. Or maybe it's the premier
" Git plugin for Vim?
" Doc: https://github.com/tpope/vim-fugitive
Plug 'tpope/vim-fugitive'
Plug 'https://github.com/tpope/vim-rhubarb.git'

set diffopt+=vertical

nmap <leader>gr :diffget //3<CR>
nmap <leader>gl :diffget //2<CR>
nmap <leader>gs :G<CR>

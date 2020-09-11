" The NERDTree is a file system explorer for the Vim editor.
" Doc: https://github.com/preservim/nerdtree
Plug 'preservim/nerdtree', { 'on':  'NERDTreeToggle' }
map <leader>t :NERDTreeToggle<CR>

" Close NERDTree after a file is opened
let g:NERDTreeQuitOnOpen=1

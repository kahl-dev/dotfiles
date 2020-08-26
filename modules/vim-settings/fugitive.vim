" Fugitive is the premier Vim plugin for Git. Or maybe it's the premier
" Git plugin for Vim?
" Doc: https://github.com/tpope/vim-fugitive
" Doc: https://github.com/shumphrey/fugitive-gitlab.vim
" Doc: https://github.com/tpope/vim-rhubarb

if &loadplugins
  if has('packages')

    packadd! vim-fugitive
    " packadd! fugitive-gitlab.vim " Add fugitive gitlab support
    " packadd! vim-rhubarb  " Add fugitive github support

  endif
endif

set diffopt+=vertical

nmap <leader>gr :diffget //3<CR>
nmap <leader>gl :diffget //2<CR>
nmap <leader>gs :G<CR>

" The plug-in visualizes undo history and makes it easier to browse and switch
" between different undo branches.
" Doc: https://github.com/mbbill/undotree

if &loadplugins
  if has('packages')

    packadd! undotree

  endif
endif


nnoremap <leader>u :UndotreeToggle<CR>

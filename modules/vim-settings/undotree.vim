" The plug-in visualizes undo history and makes it easier to browse and switch
" between different undo branches.
" Doc: https://github.com/mbbill/undotree

let g:undotree_HighlightChangedWithSign = 0
let g:undotree_WindowLayout             = 2
let g:undotree_SetFocusWhenToggle       = 1
nnoremap <leader>u :packadd undotree \| :UndotreeToggle<CR>

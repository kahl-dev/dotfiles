" Automatic folds
" Doc: https://github.com/Konfekt/FastFold

if &loadplugins
  if has('packages')

    packadd! FastFold

  endif
endif

" set viewoptions=cursor,folds,slash,unix
"
" nmap zuz <Plug>(FastFoldUpdate)
" let g:fastfold_savehook = 1
" let g:fastfold_force = 1
" let g:fastfold_fold_command_suffixes =  ['x','X','a','A','o','O','c','C','p','P']
" let g:fastfold_fold_movement_commands = [']z', '[z', 'zj', 'zk']

" let g:markdown_folding = 1
" let g:tex_fold_enabled = 1
" let g:vimsyn_folding = 'af'
" let g:xml_syntax_folding = 1
" let g:javaScript_syntax_folding = 1
" let g:sh_fold_enabled= 7
" let g:ruby_fold = 1
" let g:perl_fold = 1
" let g:perl_fold_blocks = 1
" let g:r_syntax_folding = 1
" let g:rust_fold = 1
" let g:php_folding = 1

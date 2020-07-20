" Rooter changes the working directory to the project root when you open a file or directory. 
" Doc: https://github.com/airblade/vim-rooter

if &loadplugins
  if has('packages')

    packadd! vim-rooter

  endif
endif

" dentify a project's root directory
let g:rooter_patterns = ['.git/']

" Resolve symbolic links
let g:rooter_resolve_links = 1

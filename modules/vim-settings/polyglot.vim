" Add syntax highlighting for different languages
" Doc: https://github.com/sheerun/vim-polyglot

if &loadplugins
  if has('packages')

    packadd! vim-polyglot " language pack

  endif
endif

let g:polyglot_disabled = ['jsx']

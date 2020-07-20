" This plugin is used for displaying thin vertical lines at each indentation 
" level for code indented with spaces.
" Doc: https://github.com/Yggdroot/indentLine

if &loadplugins
  if has('packages')

    packadd! indentLine

  endif
endif

let g:indentLine_fileTypeExclude = ['markdown']

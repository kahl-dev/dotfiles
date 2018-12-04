" Disable pre processors
let g:vue_disable_pre_processors=1

" Reload syntax
autocmd FileType vue syntax sync fromstart

autocmd BufRead,BufNewFile *.css,*.scss,*.less setlocal foldmethod=marker foldmarker={,}

" Also use html and javascript tools
" autocmd BufRead,BufNewFile *.vue setlocal filetype=vue.html.javascript.css

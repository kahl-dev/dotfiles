" Comment stuff out.
" Doc: https://github.com/tpope/vim-commentary
Plug 'tpope/vim-commentary'
" Add more support for vim-commentary
" Doc: https://github.com/suy/vim-context-commentstring
Plug 'suy/vim-context-commentstring'

if !exists('g:context#commentstring#table')
  let g:context#commentstring#table = {}
endif

let g:context#commentstring#table.vue = {
\    'javaScript'  : '//%s',
\    'cssStyle'    : '/*%s*/',
\    'vue_scss'    : '/*%s*/',
\}

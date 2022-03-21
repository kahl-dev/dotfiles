" Open more than just links with gx
" Docs: https://github.com/stsewd/gx-extended.vim
Plug 'stsewd/gx-extended.vim'


if exists('$SSH_CLIENT') || exists('$SSH_TTY')
  let g:netrw_http_cmd='open'
  let g:gxext#opencmd = 'open'
  let g:netrw_browsex_viewer = "open"
endif

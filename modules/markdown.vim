Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install' }

let g:mkdp_open_to_the_world = 1
if exists('$MARKDOWN_PREV_URL')
    let g:mkdp_open_ip = 'typo3.dev.louis.info'
else
    let g:mkdp_open_ip = '0.0.0.0'
endif
let g:mkdp_port = 40001
function! g:EchoUrl(url)
    :echo a:url
endfunction
let g:mkdp_browserfunc = 'g:EchoUrl'

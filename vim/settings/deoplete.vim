let g:deoplete#enable_at_startup = 1
let g:deoplete#enable_ignore_case = 1
let g:deoplete#enable_smart_case = 1
let g:deoplete#enable_camel_case = 1
let g:deoplete#enable_refresh_always = 1
let g:deoplete#max_abbr_width = 0
let g:deoplete#max_menu_width = 0
let g:deoplete#omni#input_patterns = get(g:,'deoplete#omni#input_patterns',{})

set completeopt=longest,menuone,preview
let g:deoplete#sources = {}
let g:deoplete#sources['javascript'] = ['file', 'ultisnips', 'ternjs']

" call deoplete#custom#var('tabnine', {
" \ 'line_limit': 1000,
" \ 'max_num_results': 2,
" \ })

call deoplete#custom#source('ultisnips', 'rank', 1000)
call deoplete#custom#source('ternjs', 'rank', 999)
call deoplete#custom#source('tabnine', 'rank', 998)

let g:tern_request_timeout = 1
let g:tern_request_timeout = 6000
let g:tern#command = ["tern"]
let g:tern#arguments = ["--persistent"]

" DOKU: https://github.com/carlitux/deoplete-ternjs
let g:deoplete#sources#ternjs#filetypes = ['jsx','javascript.jsx','vue']
let g:deoplete#sources#ternjs#types = 1
let g:deoplete#sources#ternjs#depths = 1
let g:deoplete#sources#ternjs#docs = 1

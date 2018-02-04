let g:ale_fixers = {}

let g:ale_fixers['javascript'] = ['prettier']
let g:ale_javascript_prettier_use_local_config = 1

let g:ale_fixers['typescript'] = ['prettier']
let g:ale_typescript_prettier_use_local_config = 1

let g:ale_fixers['css'] = ['prettier']
let g:ale_css_prettier_use_local_config = 1

let g:ale_fixers['less'] = ['prettier']
let g:ale_less_prettier_use_local_config = 1

let g:ale_fixers['scss'] = ['prettier']
let g:ale_scss_prettier_use_local_config = 1

let g:ale_fixers['json'] = ['prettier']
let g:ale_json_prettier_use_local_config = 1

let g:ale_fixers['graphql'] = ['prettier']
let g:ale_graphql_prettier_use_local_config = 1

let g:ale_fixers['markdown'] = ['prettier']
let g:ale_markdown_prettier_use_local_config = 1

let g:ale_fixers['vue'] = ['prettier']
let g:ale_vue_prettier_use_local_config = 1

" Do not lint or fix minified files.
let g:ale_pattern_options = {
\ '\.min\.js$': {'ale_linters': [], 'ale_fixers': []},
\ '\.min\.css$': {'ale_linters': [], 'ale_fixers': []},
\}

let g:airline#extensions#ale#enabled = 1
let g:ale_fix_on_save = 1

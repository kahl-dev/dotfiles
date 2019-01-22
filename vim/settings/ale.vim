let g:ale_fixers = {
  \   '*':          [ 'remove_trailing_lines', 'trim_whitespace' ],
  \   'javascript': [ 'prettier', 'eslint'],
  \   'vue':        [ 'prettier', 'eslint'],
  \   'json':       [ 'prettier' ],
  \   'markdown':   [ 'prettier' ],
  \   'css':        [ 'prettier' ],
  \   'scss':       [ 'prettier' ]
  \}

" Do not lint or fix minified files.
let g:ale_pattern_options = {
\ '\.min\.js$': {'ale_linters': [], 'ale_fixers': []},
\ '\.min\.css$': {'ale_linters': [], 'ale_fixers': []},
\}

let g:airline#extensions#ale#enabled = 1
let g:ale_fix_on_save = 1
let g:ale_cache_executable_check_failures = 1

" Change dir to git root
function! s:ALEToggleFixOnSave()
  if g:ale_fix_on_save
    let g:ale_fix_on_save = 0
  else
    let g:ale_fix_on_save = 1
  endif

  echo 'Change ale_fix_on_save to: '.g:ale_fix_on_save
endfunction

command! ALEToggleFixOnSave call s:ALEToggleFixOnSave()

let g:ale_linters = {
\   'javascript':   [ 'eslint' ],
\   'vue':          [ 'eslint' ],
\}

" Only run linters named in ale_linters settings.
let g:ale_linters_explicit = 1

let g:ale_fixers = {
\   '*':            [ 'remove_trailing_lines', 'trim_whitespace' ],
\   'javascript':   [ 'eslint', 'prettier' ],
\   'vue':          [ 'eslint', 'prettier' ],
\   'json':         [ 'prettier' ],
\   'markdown':     [ 'prettier' ],
\   'css':          [ 'prettier' ],
\   'scss':         [ 'prettier' ],
\}

" Fix files on save
let g:ale_fix_on_save = 0

" Do not lint or fix minified files.
let g:ale_pattern_options = {
\ '\.min\.js$': {'ale_linters': [], 'ale_fixers': []},
\ '\.min\.css$': {'ale_linters': [], 'ale_fixers': []},
\}

" Show errors and warnings in statusline
let g:airline#extensions#ale#enabled = 1

" Keep the sign gutter open
let g:ale_sign_column_always = 1


" let g:ale_cache_executable_check_failures = 1

" Change dir to git root
function! s:ALEToggleFixOnSave()
  if g:ale_fix_on_save
    let g:ale_fix_on_save = 0
  else
    let g:ale_fix_on_save = 1
  endif

  echo 'Toggle ale fix on save to: '.g:ale_fix_on_save
endfunction

command! ALEToggleFixOnSave call s:ALEToggleFixOnSave()
nnoremap <leader>a :ALEToggleFixOnSave<CR>

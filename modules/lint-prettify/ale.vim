let g:ale_linters = {
\   'javascript':   [ 'eslint' ],
\   'vue':          [ 'eslint' ],
\}

" Only run linters named in ale_linters settings.
let g:ale_linters_explicit = 1

" 'javascript':   [ 'prettier', 'eslint' ],
" 'vue':          [ 'prettier', 'eslint' ],
let g:ale_fixers = {
\   '*':            [ 'remove_trailing_lines', 'trim_whitespace' ],
\   'javascript':   [ 'prettier' ],
\   'vue':          [ 'prettier' ],
\   'json':         [ 'prettier' ],
\   'markdown':     [ 'prettier' ],
\   'css':          [ 'prettier' ],
\   'scss':         [ 'prettier' ],
\}

" Fix files on save
let g:ale_fix_on_save = 0

let g:ale_sign_error = "\ue00a"
let g:ale_sign_warning = "\ue009"

" highlight clear ALEErrorSign
" highlight clear ALEWarningSign

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

let g:prettier#autoformat = 0
let g:prettier#config#trailing_comma = 'es5'
let g:prettier#config#bracket_spacing = 'true'

" Enable auto prettier on execute on load
augroup AutoPrettier
  autocmd!
  au BufRead,BufNewFile *.js set filetype=javascript
  if version <= 800
    autocmd BufWritePre *.js,*.json,*.css,*.scss,*.less,*.graphql Prettier
  els
    autocmd BufWritePre *.js,*.json,*.css,*.scss,*.less,*.graphql PrettierAsync
  endif
augroup END

" Toggle prettier auto execute on save
function! ToggleAutoPrettier()
  " Switch the toggle variable
  let g:AutoPrettierToggle = !get(g:, 'AutoPrettierToggle', 1)

  " Reset group
  augroup AutoPrettier
    autocmd!
    au BufRead,BufNewFile *.js set filetype=javascript
  augroup END

  " Enable if toggled on
  if g:AutoPrettierToggle
    augroup AutoPrettier
      if v:version < 8
        autocmd BufWritePre *.js,*.json,*.css,*.scss,*.less,*.graphql Prettier
      els
        autocmd BufWritePre *.js,*.json,*.css,*.scss,*.less,*.graphql PrettierAsync
      endif
    augroup END
  endif
endfunction

command! CustomTogglePrettier call ToggleAutoPrettier()
nmap <silent> <leader>p :call ToggleAutoPrettier()<CR>

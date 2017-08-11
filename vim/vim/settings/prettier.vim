let g:prettier#autoformat = 0
let g:prettier#config#trailing_comma = 'none'
let g:prettier#config#bracket_spacing = 'true'

" Enable auto prettier on execute on load
augroup AutoPrettier
  autocmd!
  autocmd BufWritePre *.js,*.css,*.scss PrettierAsync
augroup END

" Toggle prettier auto execute on save
function! ToggleAutoPrettier()
  " Switch the toggle variable
  let g:AutoPrettierToggle = !get(g:, 'AutoPrettierToggle', 1)

  " Reset group
  augroup AutoPrettier
      autocmd!
  augroup END

  " Enable if toggled on
  if g:AutoPrettierToggle
      augroup AutoPrettier
        autocmd BufWritePre *.js,*.css,*.scss PrettierAsync
      augroup END
  endif
endfunction

command! CustomTogglePrettier call ToggleAutoPrettier()
nmap <silent> <leader>p :call ToggleAutoPrettier()<CR>

set number                  " Show line numbers
set relativenumber          " Show relative line numbers
set cursorline              " Highlight current line

" Toggle between no numbers → absolute → relative with absolute on cursor line
function! NumberToggle()
  " https://superuser.com/questions/339593/vim-toggle-number-with-relativenumber
  :let [&nu, &rnu] = [!&rnu, &nu+&rnu==1]
  if (&number == 0)
    :exe ':IndentLinesDisable'
  else
    :exe ':IndentLinesEnable'
  endif
endfunc

command! CustomToggleLinenumbers call NumberToggle()
nmap <silent> <leader>n :call NumberToggle()<CR>

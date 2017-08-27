" http://www.rushiagr.com/blog/2016/06/17/you-dont-need-vim-swap-files-and-how-to-get-rid-of-them/

" Enable autosave plugin
let g:auto_save = 1

" nly save in Normal mode periodically. If the value is changed to '1',
" then changes are saved when you are in Insert mode too, as you type, but
" I would say prefer not save in Insert mode
let g:auto_save_in_insert_mode = 0

" Silently autosave. If you disable this option by changing value to '0',
" then in the vim status, it will display "(AutoSaved at <current time>)" all
" the time, which might get annoying
let g:auto_save_silent = 1

" And now turn Vim swapfile off
set noswapfile

" save and restore folds when a file is closed and re-opened
autocmd BufWrite * mkview
autocmd BufRead * silent loadview

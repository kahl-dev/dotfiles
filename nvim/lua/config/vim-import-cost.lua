-- https://github.com/yardnsm/vim-import-cost

vim.cmd([[
  augroup import_cost_auto_run
    autocmd!
    autocmd InsertLeave *.js,*.jsx,*.ts,*.tsx ImportCost
    autocmd BufEnter *.js,*.jsx,*.ts,*.tsx ImportCost
    autocmd CursorHold *.js,*.jsx,*.ts,*.tsx ImportCost
  augroup END
]])

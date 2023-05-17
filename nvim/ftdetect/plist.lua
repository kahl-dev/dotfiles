vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = "*.plist",
  command = "set filetype=xml",
})

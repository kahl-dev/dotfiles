-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Add custom autocmds group
vim.api.nvim_create_augroup("custom_buffer", { clear = true })
-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  group = "custom_buffer",
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "zsh",
  callback = function()
    vim.bo.filetype = "bash"
  end,
})

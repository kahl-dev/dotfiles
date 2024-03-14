-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.root_spec = { { ".git" }, "cwd" }
-- vim.g.mapleader = ","
-- vim.g.maplocalleader = ","

-- Copy/Paste when using ssh on a remote server
-- Only works on Neovim >= 0.10.0
-- if vim.clipboard and vim.clipboard.osc52 then
--   vim.api.nvim_create_autocmd("VimEnter", {
--     group = augroup("ssh_clipboard"),
--     callback = function()
--       if vim.env.SSH_CONNECTION and vim.clipboard.osc52 then
--         vim.g.clipboard = {
--           name = "OSC 52",
--           copy = {
--             ["+"] = require("vim.clipboard.osc52").copy,
--             ["*"] = require("vim.clipboard.osc52").copy,
--           },
--           paste = {
--             ["+"] = require("vim.clipboard.osc52").paste,
--             ["*"] = require("vim.clipboard.osc52").paste,
--           },
--         }
--       end
--     end,
--   })
-- end

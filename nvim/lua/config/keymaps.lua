-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local Util = require("lazyvim.util")

local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  -- do not create the keymap if a lazy keys handler exists
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

if Util.has("bufferline.nvim") then
  map("n", "<leader>cgc", "<cmd>ChatGPT<CR>", { desc = "ChatGPT" })
  map("n", "<leader>cga", "<cmd>ChatGPTAct<CR>", { desc = "ChatGPTAct" })
  map("n", "<leader>cgi", "<cmd>ChatGPTEditWithInstructions<CR>", { desc = "ChatGPTEditWithInstructions" })
  map("v", "<leader>cgi", "<cmd>ChatGPTEditWithInstructions<CR>", { desc = "ChatGPTEditWithInstructions" })
  -- map("n", "<leader>cgr", "<cmd>ChatGPTRun<CR>", { desc = "ChatGPTRun" })
  -- map("v", "<leader>cgr", "<cmd>ChatGPTRun<CR>", { desc = "ChatGPTRun" })
end

vim.cmd([[
  inoremap jk <ESC>

  noremap <silent> <c-h> :<C-U>TmuxNavigateLeft<cr>
  noremap <silent> <c-j> :<C-U>TmuxNavigateDown<cr>
  noremap <silent> <c-k> :<C-U>TmuxNavigateUp<cr>
  noremap <silent> <c-l> :<C-U>TmuxNavigateRight<cr>
  noremap <silent> <c-\> :<C-U>TmuxNavigatePrevious<cr>
]])

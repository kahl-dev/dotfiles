-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Adjust the timeout length for key sequences
vim.o.timeoutlen = 100

-- shortcut for vim.keymap.set
local function map(mode, key, action, opts)
  opts = vim.tbl_extend("force", { noremap = true, silent = false }, opts or {})
  vim.keymap.set(mode, key, action, opts)
end

require("which-key").register({
  r = { name = "+reg" },
  k = {
    name = "kahl's keymaps",
    o = {
      name = "Open or OCR52",
      j = { name = "Open JIRA" },
      g = { name = "Open GIT" },
    },
  },
}, { prefix = "<leader>", mode = "n" })
require("which-key").register({ r = { name = "+reg" } }, { prefix = "<leader>", mode = "v" })

-- exit insert mode with jk
map("i", "jk", "<ESC>", { noremap = true, silent = true, desc = "<ESC>" })
map("v", "jk", "<ESC>", { noremap = true, silent = true, desc = "<ESC>" })

-- Move to next/previous quickfix item
map("n", "<leader>ch", "<cmd>cnext<CR>zz", { desc = "Forward qfixlist" })
map("n", "<leader>c;", "<cmd>cprev<CR>zz", { desc = "Backward qfixlist" })

-- Delete and paste without regitry overwrite
map("n", "<leader>rp", [["_dP]], { desc = "Paste without regitry overwrite" })
map("v", "<leader>rp", [["_dP]], { desc = "Paste without regitry overwrite" })
map("n", "<leader>rd", [["_d]], { desc = "Delete without regitry overwrite" })
map("v", "<leader>rd", [["_d]], { desc = "Delete without regitry overwrite" })

map("n", "<leader>kt", "<cmd>lua require('toggl_handler').get_ticket_id()<CR>", { desc = "Toggle ID" })
map("n", "<leader>kom", "<cmd>lua require('marked2_open').open_in_marked2()<CR>", { desc = "Marked 2" })
map("n", "<leader>koc", "<cmd>lua require('url_utils').open_url()<CR>", { desc = "URL under cursor" })
map("n", "<leader>kojb", "<cmd>lua require('url_utils').open_jira_from_branch()<CR>", { desc = "Git branch" })
map("n", "<leader>kojc", "<cmd>lua require('url_utils').open_jira_from_commit()<CR>", { desc = "Git commit" })
map("n", "<leader>kogr", "<cmd>lua require('url_utils').open_repo()<CR>", { desc = "Git repo" })
map("n", "<leader>kogb", "<cmd>lua require('url_utils').open_branch()<CR>", { desc = "Git branch" })
map("n", "<leader>kogc", "<cmd>lua require('url_utils').open_commit()<CR>", { desc = "Git commit" })
map("n", "<leader>kogf", "<cmd>lua require('url_utils').open_file()<CR>", { desc = "Git file" })

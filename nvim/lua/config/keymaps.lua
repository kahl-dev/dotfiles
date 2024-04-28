-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Adjust the timeout length for key sequences
vim.o.timeoutlen = 100

-- exit insert mode with jk
vim.keymap.set("i", "jk", "<ESC>", { noremap = true, silent = true, desc = "<ESC>" })
vim.keymap.set("v", "jk", "<ESC>", { noremap = true, silent = true, desc = "<ESC>" })

-- Retain original register when pasting
vim.keymap.set("v", "p", '"_dP')

-- Move to next/previous quickfix item
vim.keymap.set("n", "<leader>h", "<cmd>cnext<CR>zz", { desc = "Forward qfixlist" })
vim.keymap.set("n", "<leader>;", "<cmd>cprev<CR>zz", { desc = "Backward qfixlist" })

function DeleteLastWord()
  vim.cmd("normal! daw")
end
vim.api.nvim_set_keymap("n", "<M-BS>", "<cmd>lua DeleteLastWord()<CR>", { noremap = true, silent = true })

-- Delete and paste without regitry overwrite
vim.keymap.set("n", "<leader>p", [["_dP]], { desc = "Paste without regitry overwrite" })
vim.keymap.set("v", "<leader>p", [["_dP]], { desc = "Paste without regitry overwrite" })
vim.keymap.set("n", "<leader>d", [["_d]], { desc = "Delete without regitry overwrite" })
vim.keymap.set("v", "<leader>d", [["_d]], { desc = "Delete without regitry overwrite" })

require("which-key").register({
  k = {
    name = "kahl's keymaps",
    t = { "<cmd>lua require('toggl_handler').get_ticket_id()<CR>", "Get Toggl ticket ID" },
    o = {
      name = "Open or OCR52",
      m = { "<cmd>lua require('marked2_open').open_in_marked2()<CR>", "Open in Marked 2" },
      c = { "<cmd>lua require('url_utils').open_url()<CR>", "Open URL under cursor" },
      g = {
        name = "Open Git",
        r = { "<cmd>lua require('url_utils').open_repo()<CR>", "Open Git repo in browser" },
        b = { "<cmd>lua require('url_utils').open_branch()<CR>", "Open Git branch in browser" },
        c = { "<cmd>lua require('url_utils').open_commit()<CR>", "Open Git commit in browser" },
        f = { "<cmd>lua require('url_utils').open_file()<CR>", "Open current file in Git repo in browser" },
      },
    },
  },
}, { prefix = "<leader>" })

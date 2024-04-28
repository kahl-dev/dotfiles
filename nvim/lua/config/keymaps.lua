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
  ["<leader>"] = {
    C = {
      name = "Custom",
      o = {
        name = "Open URL",
      },
    },
    o = {
      name = "Open in browser",
      g = {
        name = "Git",
      },
    },
  },
})

-- Open Git repo in browser
vim.keymap.set(
  "n",
  "<leader>ogr",
  "<cmd>lua require('gitlinks').open_repo()<CR>",
  { desc = "Open Git repo in browser" }
)
vim.keymap.set(
  "n",
  "<leader>ogb",
  "<cmd>lua require('gitlinks').open_branch()<CR>",
  { desc = "Open Git branch in browser" }
)
vim.keymap.set(
  "n",
  "<leader>ogc",
  "<cmd>lua require('gitlinks').open_commit()<CR>",
  { desc = "Open Git commit in browser" }
)
vim.keymap.set(
  "n",
  "<leader>ogf",
  "<cmd>lua require('gitlinks').open_file()<CR>",
  { desc = "Open current file in Git repo in browser" }
)

-- Define a Neovim command and map it to open the URL under the cursor
vim.keymap.set("n", "<leader>oc", "<cmd>lua require('url_handler').open_url()<CR>", {
  desc = "Open URL under cursor",
  noremap = true,
  silent = true,
})

-- Define a Neovim command and map it to open the current file in Marked 2
vim.cmd("command! OpenInMarked2 lua require('marked2_open').open_in_marked2()")
vim.keymap.set(
  "n",
  "<leader>nm",
  ":OpenInMarked2<CR>",
  { desc = "Open file in Marked2", noremap = true, silent = true }
)

vim.cmd("command! GetTogglTicketId lua require('toggl_handler').get_ticket_id()")
vim.keymap.set(
  "n",
  "<leader>nx",
  ":GetTogglTicketId<CR>",
  { desc = "Get current toggle key", noremap = true, silent = true }
)


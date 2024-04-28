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

-- Unmap mappings used by tmux plugin
-- TODO(vintharas): There's likely a better way to do this.
vim.keymap.del("n", "<C-h>")
vim.keymap.del("n", "<C-j>")
vim.keymap.del("n", "<C-k>")
vim.keymap.del("n", "<C-l>")
vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>")
vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>")
vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>")
vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>")

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

-- Message to force me to use the keymaps instead of the command

-- Override the :bd command to show an error message
-- vim.cmd([[
--   command! Bd echomsg "Use SPACE b+d to close the buffer!"
--   cabbr <expr> bd "Bd"
-- ]])
--
-- -- Override the :wq command to show an error message
-- vim.cmd([[
--   command! Wq echomsg "Use SPACE q+q to save and quit!"
--   cabbr <expr> wq "Wq"
-- ]])
--
-- -- Override the :w command to show an error message
-- vim.cmd([[
--   command! W echomsg "Use <C-s> to save the file!"
--   cabbr <expr> w "W"
-- ]])

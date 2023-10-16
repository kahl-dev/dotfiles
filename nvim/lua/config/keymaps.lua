-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- exit insert mode with jk
vim.keymap.set("i", "jk", "<ESC>", { noremap = true, silent = true, desc = "<ESC>" })

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
  },
})

-- Open Git repo in browser
vim.keymap.set(
  "n",
  "<leader>Cor",
  "<cmd>lua require('gitlinks').open_repo()<CR>",
  { desc = "Open Git repo in browser" }
)
vim.keymap.set(
  "n",
  "<leader>Cob",
  "<cmd>lua require('gitlinks').open_branch()<CR>",
  { desc = "Open Git branch in browser" }
)
vim.keymap.set(
  "n",
  "<leader>Coc",
  "<cmd>lua require('gitlinks').open_commit()<CR>",
  { desc = "Open Git commit in browser" }
)
vim.keymap.set(
  "n",
  "<leader>Cof",
  "<cmd>lua require('gitlinks').open_file()<CR>",
  { desc = "Open current file in Git repo in browser" }
)

if os.getenv("SSH_CLIENT") or os.getenv("SSH_CONNECTION") then
  vim.cmd("command! SendYankToHost lua require('url_handler').send_yank_to_host()")

  -- For normal mode
  vim.keymap.set("n", "<leader>Cy", ":SendYankToHost()<CR>", {
    desc = "Send yank to host",
    noremap = true,
    silent = true,
  })
  vim.keymap.set("n", "<leader>CY", "y$<Cmd>:SendYankToHost<CR>", {
    desc = "Send yank to host until end of line",
    noremap = true,
    silent = true,
  })

  -- For visual mode
  vim.keymap.set("v", "<leader>Cy", "y<Cmd>:SendYankToHost<CR>", {

    desc = "Send yank to host",
    noremap = true,
    silent = true,
  })
  vim.keymap.set("v", "<leader>CY", "y$<Cmd>:SendYankToHost()<CR>", {
    desc = "Send yank to host until end of line",
    noremap = true,
    silent = true,
  })
end

-- Define a Neovim command and map it to open the URL under the cursor
vim.cmd("command! OpenUrlWithNcOpen lua require('url_handler').open_url_with_nc_open()")
vim.keymap.set("n", "<leader>Cou", ":OpenUrlWithNcOpen<CR>", {
  desc = "Open URL under cursor",
  noremap = true,
  silent = true,
})

-- Define a Neovim command and map it to open the current file in Marked 2
vim.cmd("command! OpenInMarked2 lua require('marked2_open').open_in_marked2()")
vim.keymap.set(
  "n",
  "<leader>Cm",
  ":OpenInMarked2<CR>",
  { desc = "Open file in Marked2", noremap = true, silent = true }
)

vim.cmd("command! GetTogglTicketId lua require('toggl_handler').get_ticket_id()")
vim.keymap.set(
  "n",
  "<leader>Cx",
  ":GetTogglTicketId<CR>",
  { desc = "Get current toggle key", noremap = true, silent = true }
)

-- Message to force me to use the keymaps instead of the command

-- Close buffer
vim.cmd([[
  command! Bd echomsg 'Use SPACE b+d to close the buffer!'
  cabbr <expr> bd 'Bd'
]])

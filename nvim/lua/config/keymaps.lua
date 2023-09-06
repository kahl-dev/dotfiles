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

local gitlinks =
  -- Open Git repo in browser
  map("n", "<leader>gur", "<cmd>lua require('gitlinks').open_repo()<CR>", { desc = "Open Git repo in browser" })
map("n", "<leader>gub", "<cmd>lua require('gitlinks').open_branch()<CR>", { desc = "Open Git branch in browser" })
map("n", "<leader>guc", "<cmd>lua require('gitlinks').open_commit()<CR>", { desc = "Open Git commit in browser" })
map(
  "n",
  "<leader>guf",
  "<cmd>lua require('gitlinks').open_file()<CR>",
  { desc = "Open current file in Git repo in browser" }
)

vim.cmd([[
  inoremap jk <ESC>

  noremap <silent> <c-h> :<C-U>TmuxNavigateLeft<cr>
  noremap <silent> <c-j> :<C-U>TmuxNavigateDown<cr>
  noremap <silent> <c-k> :<C-U>TmuxNavigateUp<cr>
  noremap <silent> <c-l> :<C-U>TmuxNavigateRight<cr>
  noremap <silent> <c-\> :<C-U>TmuxNavigatePrevious<cr>
]])

-- Delete and paste without regitry overwrite
map("n", "<leader>p", [["_dP]], { desc = "Paste without regitry overwrite" })
map("v", "<leader>p", [["_dP]], { desc = "Paste without regitry overwrite" })
map("n", "<leader>d", [["_d]], { desc = "Delete without regitry overwrite" })
map("v", "<leader>d", [["_d]], { desc = "Delete without regitry overwrite" })

_G.send_yank_to_host = function()
  if os.getenv("SSH_CLIENT") or os.getenv("SSH_CONNECTION") then
    local clip_contents = vim.fn.getreg('"')

    local base64_prefix = "base64::"
    local escaped_content = vim.fn.shellescape(clip_contents)
    local command = "echo -n " .. escaped_content .. ' | base64 -w0 | tr -d "\n"'
    local encoded_content = vim.fn.system(command)
    local final_command = "nc_yank " .. base64_prefix .. encoded_content
    local result = vim.fn.system(final_command)

    if result ~= "" then
      vim.api.nvim_echo({ { result, "ErrorMsg" } }, false, {})
    else
      vim.api.nvim_echo({ { "Yank sent to host", "Highlight" } }, false, {})
    end
  end
end

if os.getenv("SSH_CLIENT") or os.getenv("SSH_CONNECTION") then
  -- For normal mode
  vim.api.nvim_set_keymap("n", "<leader>ny", ":lua _G.send_yank_to_host()<CR>", { noremap = true, silent = true })
  vim.api.nvim_set_keymap("n", "<leader>nY", "y$<Cmd>lua _G.send_yank_to_host()<CR>", { noremap = true, silent = true })

  -- For visual mode
  vim.api.nvim_set_keymap("v", "<leader>ny", "y<Cmd>lua _G.send_yank_to_host()<CR>", { noremap = true, silent = true })
  vim.api.nvim_set_keymap("v", "<leader>nY", "y$<Cmd>lua _G.send_yank_to_host()<CR>", { noremap = true, silent = true })
end

_G.open_url_with_nc_open = function()
  local url_under_cursor = vim.fn.expand("<cfile>")
  if url_under_cursor ~= "" then
    if os.getenv("SSH_CLIENT") or os.getenv("SSH_CONNECTION") then
      local nc_open_path = "nc_open" -- replace with actual path if needed
      local result = vim.fn.system(nc_open_path .. " " .. vim.fn.shellescape(url_under_cursor))
      if result ~= "" then
        vim.api.nvim_echo({ { result, "ErrorMsg" } }, false, {})
      else
        vim.api.nvim_echo({ { "URL opened with nc_open", "Highlight" } }, false, {})
      end
    else
      -- Local environment, use open command
      local result = vim.fn.system("open " .. vim.fn.shellescape(url_under_cursor))
      if result ~= "" then
        vim.api.nvim_echo({ { result, "ErrorMsg" } }, false, {})
      else
        vim.api.nvim_echo({ { "URL opened with default browser", "Highlight" } }, false, {})
      end
    end
  end
end

if os.getenv("SSH_CLIENT") or os.getenv("SSH_CONNECTION") then
  vim.api.nvim_set_keymap("n", "<leader>no", ":lua _G.open_url_with_nc_open()<CR>", { noremap = true, silent = true })
end

-- Define a Neovim command that calls the function
vim.cmd("command! OpenInMarked2 lua require('marked2_open').open_in_marked2()")

-- Set up the keymap to call the command
vim.api.nvim_set_keymap("n", "<leader>Cm", ":OpenInMarked2<CR>", { noremap = true, silent = true })

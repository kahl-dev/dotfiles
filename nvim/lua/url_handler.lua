local M = {}
local osc52 = require("osc52")

-- Determine if Neovim is running locally or remotely
local function is_remote()
  -- Simple check for common environment variable set by SSH sessions
  return vim.env.SSH_CONNECTION ~= nil
end

M.open_url = function()
  local url_under_cursor = vim.fn.expand("<cfile>")
  if url_under_cursor ~= "" then
    if is_remote() then
      -- In a remote session, copy URL to clipboard via OSC52
      osc52.copy(url_under_cursor)
      vim.api.nvim_echo({ { "URL copied to clipboard via OSC52", "Highlight" } }, false, {})
    else
      -- In a local session, open the URL with the system default browser
      vim.fn.jobstart("open " .. vim.fn.shellescape(url_under_cursor), { detach = true })
      vim.api.nvim_echo({ { "URL opened in browser", "Highlight" } }, false, {})
    end
  else
    vim.api.nvim_echo({ { "No URL found under cursor", "WarningMsg" } }, false, {})
  end
end

return M

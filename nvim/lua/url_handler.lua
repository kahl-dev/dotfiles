local M = {}
local osc52 = require("osc52")

M.open_url = function()
  local url_under_cursor = vim.fn.expand("<cfile>")
  if url_under_cursor ~= "" then
    osc52.copy(url_under_cursor)
    vim.api.nvim_echo({ { "URL copied to clipboard", "Highlight" } }, false, {})
  end
end

return M

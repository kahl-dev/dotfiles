local M = {}

M.open_url_with_nc_open = function()
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

M.send_yank_to_host = function()
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

return M

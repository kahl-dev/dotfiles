local M = {}

M.open_in_marked2 = function()
  -- Check if we're on OSX
  if vim.fn.has("macunix") == 1 then
    -- Check if Marked 2 is installed
    local is_installed = vim.fn.system("osascript -e 'id of app \"Marked 2\"'")
    print(is_installed)
    if is_installed == "com.brettterpstra.marked2\n" then
      local current_file = vim.fn.expand("%")
      if current_file:match("%.md$") then
        -- Open the file in Marked 2
        vim.cmd('!open -a "Marked 2" ' .. current_file)
      else
        print("The current file is not a Markdown file.")
      end
    else
      print("Marked 2 is not installed.")
    end
  else
    print("This function is only available on OSX.")
  end
end

return M

-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.node_host_prog = os.getenv("NEOVIM_NODE_HOST")

vim.g.root_spec = { { ".git" }, "cwd" }

-- Use rclip for clipboard operations everywhere
vim.g.clipboard = {
  name = "rclip",
  copy = {
    ["+"] = "rclip",
    ["*"] = "rclip",
  },
  paste = {
    ["+"] = function()
      -- For now, fallback to system clipboard for paste
      -- TODO: Add paste support to rclip if needed
      if vim.fn.executable("pbpaste") == 1 then
        local handle = io.popen("pbpaste")
        if handle then
          local result = handle:read("*a")
          handle:close()
          if result then
            return vim.split(result, "\n")
          end
        end
      end
      return {}
    end,
    ["*"] = function()
      return vim.g.clipboard.paste["+"]()
    end,
  },
  cache_enabled = 0,
}

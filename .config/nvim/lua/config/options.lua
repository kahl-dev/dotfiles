-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.node_host_prog = os.getenv("NEOVIM_NODE_HOST")

vim.g.root_spec = { { ".git" }, "cwd" }

-- Universal clipboard configuration for all environments
-- Prioritizes tmux buffer for SSH scenarios, OSC 52 for local
vim.g.clipboard = {
  name = "Universal clipboard",
  copy = {
    ["+"] = function(lines)
      local text = table.concat(lines, "\n")
      
      -- Use universal-clipboard script which handles all scenarios
      local handle = io.popen("universal-clipboard", "w")
      if handle then
        handle:write(text)
        handle:close()
      end
    end,
    ["*"] = function(lines)
      return vim.g.clipboard.copy["+"](lines)
    end,
  },
  paste = {
    -- For paste, try multiple sources in order of preference
    ["+"] = function()
      -- Try tmux buffer first (fastest for tmux environments)
      if vim.env.TMUX then
        local handle = io.popen("tmux save-buffer - 2>/dev/null")
        if handle then
          local result = handle:read("*a")
          handle:close()
          if result and result ~= "" then
            return vim.split(result, "\n")
          end
        end
      end
      
      -- Fallback to pbpaste for local environments
      if not vim.env.SSH_TTY and vim.fn.executable("pbpaste") == 1 then
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
  cache_enabled = 0, -- Disable cache to ensure fresh data
}

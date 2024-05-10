-- docs: https://github.com/zeioth/garbage-day.nvim

return {
  {
    "zeioth/garbage-day.nvim",
    dependencies = "neovim/nvim-lspconfig",
    event = "VeryLazy",
    opts = {
      -- Available options
      -- https://github.com/Zeioth/garbage-day.nvim?tab=readme-ov-file#available-options
      -- aggressive_mode = false,
      excluded_lsp_clients = { "copilot" },
      grace_period = 60 * 30, -- Seconds
      -- wakeup_delay = 0,

      -- Debug options
      -- https://github.com/Zeioth/garbage-day.nvim?tab=readme-ov-file#debug-options
      -- aggressive_mode_ignore = ,
      notifications = true,
      retries = 5,
      timeout = 1000, -- milliseconds
    },
  },
}

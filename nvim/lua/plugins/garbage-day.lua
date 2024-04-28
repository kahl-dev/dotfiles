-- docs: https://github.com/zeioth/garbage-day.nvim

return {
  {
    "zeioth/garbage-day.nvim",
    dependencies = "neovim/nvim-lspconfig",
    event = "VeryLazy",
    opts = {
      notifications = true,
    },
  },
}

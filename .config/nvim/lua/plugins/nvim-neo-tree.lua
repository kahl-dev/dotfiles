-- Plugin to manage files and directories
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
        },
      },
    },
  },
}

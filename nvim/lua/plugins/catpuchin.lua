return {
  {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      opts.colorscheme = "catppuccin"
      return opts
    end,
  },

  {
    "catppuccin/nvim",
    lazy = true,
    name = "catppuccin",
    opts = function(_, opts)
      -- require("notify").setup(vim.tbl_extend("keep", {
      --   background_colour = "#000000",
      -- }, opts))

      opts.transparent_background = true
      return opts
    end,
  },
}

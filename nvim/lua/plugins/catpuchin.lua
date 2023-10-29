return {
  {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      opts.colorscheme = "catppuccin"
      opts.install = { colorscheme = { "catppuchin" } }
      -- automatically check for plugin updates
      opts.checker = { enabled = true, frequency = 86400 }
      return opts
    end,
  },

  {
    "catppuccin/nvim",
    lazy = true,
    name = "catppuccin",
    opts = function(_, opts)
      require("notify").setup(vim.tbl_extend("keep", {
        background_colour = "#000000",
      }, opts))

      opts.transparent_background = true
      return opts
    end,
  },
}

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
    opts = {
      transparent_background = true,
      integrations = { blink_cmp = true },
    },
  },
}

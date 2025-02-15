-- docs: https://github.com/folke/snacks.nvim

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      return vim.tbl_deep_extend("force", opts or {}, {
        picker = {
          sources = {
            files = { hidden = true },
            grep = { hidden = true },
            explorer = { hidden = true },
          },
        },
      })
    end,
  },
}

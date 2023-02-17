return {
  "hrsh7th/nvim-cmp",

  dependencies = {
    { "hrsh7th/cmp-copilot", dependencies = {
      "github/copilot.vim",
    } },
  },
  ---@param opts cmp.ConfigSchema
  opts = function(_, opts)
    local cmp = require("cmp")
    opts.sources = cmp.config.sources(vim.list_extend(opts.sources, { { name = "copilot" } }))
    opts.mapping = cmp.config.mapping(vim.list_extend(opts.mapping, {
      ["<C-g>"] = cmp.mapping(function(fallback)
        vim.api.nvim_feedkeys(
          vim.fn["copilot#Accept"](vim.api.nvim_replace_termcodes("<Tab>", true, true, true)),
          "n",
          true
        )
      end),
    }))

    opts.experimental = {
      ghost_text = false, -- this feature conflict with copilot.vim's preview.
    }
  end,
}

-- Nvim Treesitter configurations and abstraction layer
-- https://github.com/nvim-treesitter/nvim-treesitter

return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    opts.textobjects = {
      lsp_interop = {
        enable = true,
        border = "single",
        floating_preview_opts = {},
        peek_definition_code = {
          ["<leader>df"] = "@function.outer",
          ["<leader>dF"] = "@class.outer",
        },
      },
    }

    -- add tsx and treesitter
    vim.list_extend(opts.ensure_installed, {
      "arduino",
      "bash",
      "comment",
      "css",
      "csv",
      "graphql",
      "html",
      "javascript",
      "json5",
      "json",
      "jsdoc",
      "lua",
      "markdown",
      "php",
      "regex",
      "scss",
      "prisma",
      "tsx",
      "typescript",
      "vue",
    })
  end,
}

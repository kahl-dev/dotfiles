-- Nvim Treesitter configurations and abstraction layer
-- https://github.com/nvim-treesitter/nvim-treesitter

return {
  "nvim-treesitter/nvim-treesitter",
  commit = "19ac9e8b5c1e5eedd2ae7957243e25b32e269ea7",
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

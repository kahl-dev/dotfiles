-- Nvim Treesitter configurations and abstraction layer
-- https://github.com/nvim-treesitter/nvim-treesitter

return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
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

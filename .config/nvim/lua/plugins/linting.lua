return {
  "mfussenegger/nvim-lint",
  opts = {
    linters_by_ft = {
      -- Disable markdown linting for make files
      make = {},
    },
  },
  config = function(_, opts)
    local lint = require("lint")
    
    -- Override LazyVim's default markdown linter setup
    lint.linters_by_ft = vim.tbl_deep_extend("force", lint.linters_by_ft or {}, opts.linters_by_ft or {})
    
    -- Create autocmd to disable markdown diagnostics for Makefiles
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
      pattern = { "Makefile", "makefile", "*.mk", "*.make" },
      callback = function()
        -- Disable markdown diagnostics for this buffer
        vim.diagnostic.disable(0, vim.lsp.get_clients({ name = "markdownlint" })[1] and vim.lsp.get_clients({ name = "markdownlint" })[1].id)
      end,
    })
  end,
}
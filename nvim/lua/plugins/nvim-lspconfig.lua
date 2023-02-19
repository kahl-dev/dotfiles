-- Quickstart configs for Nvim LSP
-- https://github.com/neovim/nvim-lspconfig

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      format = {
        async = true,
      },
      setup = {
        tsserver = function(_, opts)
          opts.capabilities.documentFormattingProvider = true
        end,
        eslint = function(_, opts)
          opts.capabilities.documentFormattingProvider = true
        end,
        prettier = function(_, opts)
          opts.capabilities.documentFormattingProvider = true
        end,
      },
    },
  },
}

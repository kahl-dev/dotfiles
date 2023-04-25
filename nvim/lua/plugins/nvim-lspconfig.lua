-- Quickstart configs for Nvim LSP
-- https://github.com/neovim/nvim-lspconfig

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tailwindcss = {},
        volar = {},
        docker_compose_language_service = {},
        prismals = {},
        shellcheck = {},
      },
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

-- Quickstart configs for Nvim LSP
-- https://github.com/neovim/nvim-lspconfig

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        cssls = {},
        volar = {},
        docker_compose_language_service = {},
        prismals = {},
        -- https://github.com/aca/emmet-ls
        emmet_ls = {},
        marksman = {},
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

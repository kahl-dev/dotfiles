-- Quickstart configs for Nvim LSP
-- https://github.com/neovim/nvim-lspconfig

local compat = require("config.lsp-compat")

compat.ensure_modern_node()

return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      volar = {
        filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
        init_options = { vue = { hybridMode = false } },
        on_attach = compat.disable_nuxt_formatting,
      },
      vtsls = {
        settings = {
          typescript = {
            tsdk = compat.resolve_tsdk(),
            tsserver = { experimental = { enableProjectDiagnostics = true } },
          },
        },
        on_attach = compat.disable_nuxt_formatting,
      },
    },
    format = { async = true },
  },
}

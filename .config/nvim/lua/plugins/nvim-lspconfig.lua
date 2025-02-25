-- Quickstart configs for Nvim LSP
-- https://github.com/neovim/nvim-lspconfig

return {
  "neovim/nvim-lspconfig",
  opts = {
    -- inlay_hints = {
    --   enabled = false,
    -- },
    servers = {
      -- None hybrid mode where volar also handles typescript
      volar = {
        filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
        init_options = {
          vue = {
            hybridMode = false,
          },
        },
      },

      vtsls = {
        settings = {
          typescript = {
            tsserver = {
              experimental = {
                enableProjectDiagnostics = true,
              },
            },
          },
        },
      },
    },
    format = {
      async = true,
    },
  },
}

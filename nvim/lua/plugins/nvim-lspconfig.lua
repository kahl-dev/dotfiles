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
        -- https://github.com/aca/emmet-ls
        emmet_ls = {
          -- filetype = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
          -- init_options = {
          --   config = {
          --     emmet = {
          --       variables = {
          --         ["lang.scss"] = "scss",
          --         ["lang.less"] = "less",
          --         ["lang.stylus"] = "stylus",
          --       },
          --     },
          --   },
          -- },
        },
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

-- Quickstart configs for Nvim LSP
-- https://github.com/neovim/nvim-lspconfig

-- Retrieve values from environment variables
local username_from_env = os.getenv("LTEX_USERNAME")
local apiKey_from_env = os.getenv("LTEX_APIKEY")

return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      -- cssls = {},
      -- tsserver = {},
      volar = {
        filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
        init_options = {
          vue = {
            hybridMode = false,
          },
        },
      },
      -- docker_compose_language_service = {},
      prismals = {},
      -- https://github.com/aca/emmet-ls
      emmet_ls = {},
      marksman = {},
      -- ltex = {
      --   enabled = { "latex", "tex", "bib", "md" },
      --   checkFrequency = "save",
      --   diagnosticSeverity = "information",
      --   setenceCacheSize = 5000,
      --   -- language = "en-US",
      --   -- language = "de-DE",
      --   -- additionalRules = {
      --   --   enablePickyRules = true,
      --   --   motherTongue = "de-DE",
      --   -- },
      --   trace = { server = "verbose" },
      --   languageToolOrg = {
      --     username = username_from_env, -- Set the value from the env variable
      --     apiKey = apiKey_from_env, -- Set the value from the env variable
      --   },
      --   completionEnabled = true,
      -- },
      -- arduino_language_server = {},

      -- For Bash scripts
      -- spellcheck = {},
      bashls = {},

      -- Dont use because of memory issues
      intelephense = {},
    },
    format = {
      async = true,
    },
    setup = {
      -- tsserver = function(_, opts)
      --   opts.capabilities.documentFormattingProvider = true
      -- end,
      -- eslint = function(_, opts)
      --   opts.capabilities.documentFormattingProvider = true
      -- end,
      -- prettier = function(_, opts)
      --   opts.capabilities.documentFormattingProvider = true
      -- end,
    },
  },
}

-- Quickstart configs for Nvim LSP
-- https://github.com/neovim/nvim-lspconfig

-- Retrieve values from environment variables
local username_from_env = os.getenv("LTEX_USERNAME")
local apiKey_from_env = os.getenv("LTEX_APIKEY")

local home = os.getenv("HOME")
local vue_language_server_path = home
  .. "/.local/share/nvim/mason/packages/vue-language-server/node_modules/@vue/language-server"

return {
  "neovim/nvim-lspconfig",
  opts = {
    -- inlay_hints = {
    --   enabled = false,
    -- },
    servers = {
      -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#cssls
      -- npm i -g vscode-langservers-extracted
      cssls = {},

      -- Hybrid mode where volar only handles vue and typescript by itself
      -- tsserver = {
      --   init_options = {
      --     plugins = {
      --       {
      --         name = "@vue/typescript-plugin",
      --         location = vue_language_server_path,
      --         languages = { "vue" },
      --       },
      --     },
      --   },
      --   filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
      -- },

      -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#emmet_ls
      -- npm install -g emmet-ls
      emmet_ls = {},

      -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#marksman
      marksman = {},

      -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#bashls
      -- npm i -g bash-language-server
      bashls = {
        filetypes = { "sh", "bash", "zsh" },
      },

      -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#prismals
      -- npm install -g @prisma/language-server
      -- prismals = {},

      -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#prismals
      -- go install github.com/arduino/arduino-language-server@latest
      -- arduino_language_server = {},

      -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#intelephense
      -- npm install -g intelephense
      -- intelephense = {},

      -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#cssls
      -- https://github.com/vuejs/language-tools
      -- npm install -g typescript typescript-language-server

      -- None hybrid mode where volar also handles typescript
      -- volar = {
      --   filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
      --   init_options = {
      --     vue = {
      --       hybridMode = false,
      --     },
      --   },
      -- },

      -- None hybrid mode where volar only handles vue and typescript by itself
      -- tsserver = {
      --   init_options = {
      --     plugins = {
      --       {
      --         name = "@vue/typescript-plugin",
      --         location = vue_language_server_path,
      --         languages = { "vue" },
      --       },
      --     },
      --   },
      --
      --   volar = {
      --     init_options = {
      --       vue = {
      --         hybridMode = false,
      --       },
      --     },
      --   },
      -- },
    },
    -- format = {
    --   async = true,
    -- },
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

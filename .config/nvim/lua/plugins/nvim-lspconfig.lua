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
        on_attach = function(client, bufnr)
          -- Helper function to find Nuxt root
          local function find_nuxt_root(buf)
            local bufname = vim.api.nvim_buf_get_name(buf)
            if bufname == "" then return nil end
            local current_dir = vim.fn.fnamemodify(bufname, ":h")
            while current_dir ~= "/" do
              for _, cfg in ipairs({"nuxt.config.ts", "nuxt.config.js", "nuxt.config.mjs"}) do
                if vim.fn.filereadable(current_dir .. "/" .. cfg) == 1 then
                  return current_dir
                end
              end
              current_dir = vim.fn.fnamemodify(current_dir, ":h")
            end
            return nil
          end

          -- Disable formatting only in Nuxt projects
          if find_nuxt_root(bufnr) then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end
        end,
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
        on_attach = function(client, bufnr)
          -- Helper function to find Nuxt root
          local function find_nuxt_root(buf)
            local bufname = vim.api.nvim_buf_get_name(buf)
            if bufname == "" then return nil end
            local current_dir = vim.fn.fnamemodify(bufname, ":h")
            while current_dir ~= "/" do
              for _, cfg in ipairs({"nuxt.config.ts", "nuxt.config.js", "nuxt.config.mjs"}) do
                if vim.fn.filereadable(current_dir .. "/" .. cfg) == 1 then
                  return current_dir
                end
              end
              current_dir = vim.fn.fnamemodify(current_dir, ":h")
            end
            return nil
          end

          -- Disable formatting only in Nuxt projects
          if find_nuxt_root(bufnr) then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end
        end,
      },
    },
    format = {
      async = true,
    },
  },
}

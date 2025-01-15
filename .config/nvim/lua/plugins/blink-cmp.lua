return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        -- ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
      },
      sources = {
        min_keyword_length = function(ctx)
          return ctx.trigger.kind == "manual" and 0 or 2
        end,
        providers = {
          snippets = {
            opts = {
              search_paths = { "/home/kahl/dev/snippets/lia-typo3-vscode" },
            },
          },
        },
      },
    },

    opts_extend = { "sources.providers.snippets.opts.search_paths", "keymaps" },
  },

  -- workaround for make <C-k> work in saghen/blink.cmp
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      keys[#keys + 1] = { "<C-k>", false, mode = { "i" } }

      opts.servers.eslint.settings.workingDirectory = { mode = "auto" }
      opts.inlay_hints = { enabled = false }
      opts.setup.eslint = function()
        require("lazyvim.util").lsp.on_attach(function(client)
          if client.name == "eslint" then
            client.server_capabilities.documentFormattingProvider = true
          elseif client.name == "tsserver" then
            client.server_capabilities.documentFormattingProvider = false
          end
        end)
        vim.cmd([[autocmd BufWritePre *.tsx,*.ts,*.jsx,*.js EslintFixAll]])
      end
      return opts
    end,
  },
}

return {
  {
    "saghen/blink.cmp",
    version = "0.8.2", -- Plugin version for compatibility.
    -- opts = function(_, opts)
    --   -- Ensures the specified nested path exists in a table, creating tables as needed.
    --   local function ensure_path(obj, path)
    --     for _, key in ipairs(path) do
    --       obj[key] = obj[key] or {} -- Create the table if it doesn't exist.
    --       obj = obj[key] -- Navigate deeper into the structure.
    --     end
    --     return obj -- Return the final table for further modifications.
    --   end
    --
    --   local snippet_path = "/home/kahl/dev/snippets/lia-typo3-vscode"
    --   if vim.fn.isdirectory(snippet_path) == 1 then
    --     -- Ensure the nested structure exists and set the snippet search path.
    --     ensure_path(opts, { "sources", "providers", "snippets", "opts" }).search_paths = { snippet_path }
    --   end
    --
    --   -- Configure key mappings for navigating suggestions.
    --   opts.keymap = {
    --     ["<C-k>"] = { "select_prev", "fallback" },
    --     ["<C-j>"] = { "select_next", "fallback" },
    --   }
    --
    --   return opts -- Return the updated configuration.
    -- end,
    opts = {
      keymap = {
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
      },
      -- source = {
      --   providers = {
      --     snippets = {
      --       opts = {
      --         search_paths = { "/home/kahl/dev/snippets/lia-typo3-vscode" },
      --       },
      --     },
      --   },
      -- },
    },
    -- opts_extend = { "sources.providers.snippets.opts.search_paths", "keymaps" },
    opts_extend = { "keymaps" },
  },

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

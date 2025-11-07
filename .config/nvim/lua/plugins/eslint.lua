-- ESLint LSP configuration with Nuxt project detection
-- Uses ESLint LSP server for formatting (not conform.nvim)
return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    -- Helper: Find Nuxt root by walking up directory tree
    local function find_nuxt_root(bufnr)
      bufnr = bufnr or vim.api.nvim_get_current_buf()
      local bufname = vim.api.nvim_buf_get_name(bufnr)

      if bufname == "" then
        return nil
      end

      local current_dir = vim.fn.fnamemodify(bufname, ":h")

      while current_dir ~= "/" do
        for _, config in ipairs({"nuxt.config.ts", "nuxt.config.js", "nuxt.config.mjs"}) do
          if vim.fn.filereadable(current_dir .. "/" .. config) == 1 then
            return current_dir
          end
        end
        current_dir = vim.fn.fnamemodify(current_dir, ":h")
      end

      return nil
    end

    -- Configure ESLint LSP server
    opts.servers = opts.servers or {}
    opts.servers.eslint = {
      settings = {
        workingDirectories = { mode = "auto" },
      },
      -- Only activate in Nuxt projects
      root_dir = function(fname)
        local util = require("lspconfig.util")
        -- Look for Nuxt config files
        return util.root_pattern("nuxt.config.ts", "nuxt.config.js", "nuxt.config.mjs")(fname)
      end,
      on_attach = function(client, bufnr)
        -- Only enable formatting in Nuxt projects
        if find_nuxt_root(bufnr) then
          -- ESLint LSP can format
          client.server_capabilities.documentFormattingProvider = true

          -- Auto-format on save using ESLint LSP
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({
                bufnr = bufnr,
                filter = function(c)
                  return c.name == "eslint"
                end,
              })
            end,
          })
        end
      end,
    }

    return opts
  end,
}

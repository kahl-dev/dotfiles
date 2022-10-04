local M = {}

function M.setup()

  local status_ok, null_ls = pcall(require, "null-ls")
  if not status_ok then
    return
  end

  -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
  local formatting = null_ls.builtins.formatting
  -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
  -- local diagnostics = null_ls.builtins.diagnostics

-- local lsp_formatting = function(bufnr)
-- 	vim.lsp.buf.format({
-- 		filter = function(client)
-- 			-- apply whatever logic you want (in this example, we'll only use null-ls)
-- 			return client.name == "null-ls"
-- 		end,
-- 		bufnr = bufnr,
-- 	})
-- end

-- if you want to set up formatting on save, you can use this as a callback
-- local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

  local null_ls_settings = {
    debug = true,
    sources = {
      formatting.eslint_d,
      formatting.prettier,
      formatting.stylua,
    },

    -- on_attach = function(client, bufnr)
    --   if client.supports_method("textDocument/formatting") then
    --     vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
    --     vim.api.nvim_create_autocmd("BufWritePre", {
    --       group = augroup,
    --       buffer = bufnr,
    --       callback = function()
    --         lsp_formatting(bufnr)
    --         -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
    --         vim.lsp.buf.format({ async = false })
    --       end,
    --     })
    --   end
    -- end,
  }

  local default_opts = require("config.lsp").get_common_opts()
  null_ls.setup(vim.tbl_deep_extend("force", default_opts, null_ls_settings))
end

return M

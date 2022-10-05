local M = {}

function M.setup()
	local status_ok, null_ls = pcall(require, "null-ls")
	if not status_ok then
		return
	end

	-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
	local formatting = null_ls.builtins.formatting
	-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
	local diagnostics = null_ls.builtins.diagnostics

	-- if you want to set up formatting on save, you can use this as a callback
	local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

	local null_ls_settings = {
		debug = false,
		sources = {
			formatting.eslint_d,
			formatting.prettier,
			formatting.stylua,
		},

		-- you can reuse a shared lspconfig on_attach callback here
		on_attach = function(client, bufnr)
			if client.supports_method("textDocument/formatting") then
				vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
				vim.api.nvim_create_autocmd("BufWritePre", {
					group = augroup,
					buffer = bufnr,
					callback = function()
						vim.lsp.buf.format({
							bufnr = bufnr,
							filter = function(client)
								return client.name == "null-ls"
							end,
						})
					end,
				})
			end
		end,
	}

	local default_opts = require("config.lsp").get_common_opts()
	null_ls.setup(vim.tbl_deep_extend("force", default_opts, null_ls_settings))

	local mason_status_ok, mason_null_ls = pcall(require, "mason-null-ls")
	if not mason_status_ok then
		return
	end

  mason_null_ls.setup({
    ensure_installed = { "stylua", "prettier", "eslint_d"},
    automatic_installation = false,
  })
end

return M

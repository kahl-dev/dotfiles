local M = {}

function M.setup()
	local mason_status_ok, mason = pcall(require, "mason")
	if not mason_status_ok then
		return
	end

	local mason_lspconfig_status_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
	if not mason_lspconfig_status_ok then
		return
	end

	mason.setup({
		ui = {
			icons = {
				package_installed = "✓",
			},
		},
	})

	-- https://github.com/williamboman/mason-lspconfig.nvim#available-lsp-servers
	mason_lspconfig.setup({
		ensure_installed = {
			"bashls",
			"cssls",
			"eslint",
			"emmet_ls",
			"html",
			"stylelint_lsp",
			"sumneko_lua",
			"tailwindcss",
			"tsserver",
			"volar",
		},
		automatic_installation = false,
	})

	local status, lspconfig = pcall(require, "lspconfig")
	if not status then
		return
	end

	mason_lspconfig.setup_handlers({
		function(server_name)
			local opts = require("config.lsp").get_common_opts()

			if server_name == "jsonls" then
				local jsonls_opts = require("config.lsp.settings.jsonls")
				opts = vim.tbl_deep_extend("force", jsonls_opts, opts)
			end

			if server_name == "sumneko_lua" then
				local sumneko_opts = require("config.lsp.settings.sumneko_lua")
				opts = vim.tbl_deep_extend("force", sumneko_opts, opts)
			end

			lspconfig[server_name].setup(opts)
		end,
	})
end

return M

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
			"esling",
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
			lspconfig[server_name].setup(require("config.lsp").get_common_opts())
		end,
	})
end

return M

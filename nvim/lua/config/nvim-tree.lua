-- https://github.com/kyazdani42/nvim-tree.lua

local status_ok, nvim_tree = pcall(require, "nvim-tree")
if not status_ok then
	return
end

vim.g.loaded = 1
vim.g.loaded_netrwPlugin = 1

nvim_tree.setup({
	update_focused_file = {
		enable = true,
		update_cwd = true,
	},
	diagnostics = {
		enable = true,
		show_on_dirs = true,
	},
})

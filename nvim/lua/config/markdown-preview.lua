-- https://github.com/iamcco/markdown-preview.nvim

-- vim.cmd([[
-- function OpenMarkdownPreview (url)
--   execute "terminal open " . a:url
-- endfunction
-- ]])

-- vim.g.mkdp_browserfunc = "OpenMarkdownPreview"
vim.g.mkdp_echo_preview_url = 1
vim.g.mkdp_port = "44444"
vim.g.mkdp_browser = "xdg-open"
vim.g.mkdp_open_to_the_world = 1
vim.g.mkdp_refresh_slow = 0

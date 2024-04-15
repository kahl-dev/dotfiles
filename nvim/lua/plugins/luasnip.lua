-- Snippet Engine for Neovim written in Lua.
-- https://github.com/L3MON4D3/LuaSnip

return {
  "L3MON4D3/LuaSnip",
  config = function()
    local snippet_paths = { "~/.config/nvim/my_snippets" }

    -- use Neovim's globpath to get all subdirectories of ~/dev/snippets
    local dirs = vim.fn.globpath("~/dev/snippets", "*/", 0, 1)

    for _, dir in pairs(dirs) do
      table.insert(snippet_paths, dir)
    end

    require("luasnip.loaders.from_vscode").lazy_load({
      paths = snippet_paths,
    })
  end,
}

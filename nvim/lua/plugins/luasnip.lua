-- Snippet Engine for Neovim written in Lua.
-- https://github.com/L3MON4D3/LuaSnip

return {
  "L3MON4D3/LuaSnip",
  build = (not jit.os:find("Windows"))
      and "echo 'NOTE: jsregexp is optional, so not a big deal if it fails to build'; make install_jsregexp"
    or nil,
  dependencies = {
    "rafamadriz/friendly-snippets",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
  opts = {
    history = true,
    delete_check_events = "TextChanged",
  },
  -- stylua: ignore
  keys = {
    {
      "<tab>",
      function()
        return require("luasnip").jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
      end,
      expr = true, silent = true, mode = "i",
    },
    { "<tab>", function() require("luasnip").jump(1) end, mode = "s" },
    { "<s-tab>", function() require("luasnip").jump(-1) end, mode = { "i", "s" } },
  },

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

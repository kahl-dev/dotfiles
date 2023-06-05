-- A clean, dark Neovim theme written in Lua, with support for lsp, treesitter
-- and lots of plugins. Includes additional themes for Kitty, Alacritty,
-- iTerm and Fish.
-- https://github.com/folke/tokyonight.nvim

return {
  "folke/tokyonight.nvim",
  opts = {
    style = "night",
    transparent = true,
    styles = {
      sidebars = "transparent",
      floats = "transparent",
    },
  },
}

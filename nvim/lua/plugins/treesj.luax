return {
  "Wansmer/treesj",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("treesj").setup()
  end,
  keys = {
    {
      "<leader>ct",
      function()
        require("treesj").toggle()
      end,
      desc = "Find Plugin File",
    },
  },
  cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
  opts = { use_default_keymaps = false },
}

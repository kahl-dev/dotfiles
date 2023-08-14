-- ChatGPT Neovim Plugin: Effortless Natural Language Generation with OpenAI's
-- ChatGPT API
-- https://github.com/jackMort/ChatGPT.nvim

return {
  "jackMort/ChatGPT.nvim",
  event = "VeryLazy",
  commit = "2107f70",

  config = function()
    require("chatgpt").setup()

    -- Set the key as OPENAI_API_KEY in your shell
    -- require("chatgpt").setup({
    --   api_key_cmd = "",
    -- })
    -- chat = {
    --   keymaps = {
    --     close = { "jk", "kj", "<Esc>" },
    --     yank_last = "<C-y>",
    --     scroll_up = "<C-u>",
    --     scroll_down = "<C-d>",
    --     toggle_settings = "<C-o>",
    --     new_session = "<C-n>",
    --     cycle_windows = "<Tab>",
    --   },
    -- },
    -- popup_input = {
    --   -- submit = "<C-s>",
    --   submit = "<CR>",
    -- },
  end,

  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
}

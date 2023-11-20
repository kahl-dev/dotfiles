-- ChatGPT Neovim Plugin: Effortless Natural Language Generation with OpenAI's
-- ChatGPT API
-- https://github.com/jackMort/ChatGPT.nvim

return {
  "jackMort/ChatGPT.nvim",
  event = "VeryLazy",
  -- commit = "2107f70",

  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },

  config = function()
    require("which-key").register({
      ["<leader>"] = {
        G = {
          name = "ChatGPT",
        },
      },
    })
    -- require("chatgpt").setup()

    -- Set the key as OPENAI_API_KEY in your shell
    require("chatgpt").setup({
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
      openai_params = {
        model = "gpt-4-1106-preview",
        -- model = "gpt-4",
        -- max_tokens = 1000,
        max_tokens = 4096,
      },
      openai_edit_params = {
        model = "gpt-4-1106-preview",
        -- model = "gpt-4",
      },
    })
  end,
  keys = {
    { "<leader>Gc", "<cmd>ChatGPT<CR>", desc = "ChatGPT" },
    { "<leader>Ge", "<cmd>ChatGPTEditWithInstruction<CR>", desc = "Edit with instruction", mode = { "n", "v" } },
    { "<leader>Gg", "<cmd>ChatGPTRun grammar_correction<CR>", desc = "Grammar Correction", mode = { "n", "v" } },
    { "<leader>Gt", "<cmd>ChatGPTRun translate<CR>", desc = "Translate", mode = { "n", "v" } },
    { "<leader>Gk", "<cmd>ChatGPTRun keywords<CR>", desc = "Keywords", mode = { "n", "v" } },
    { "<leader>Gd", "<cmd>ChatGPTRun docstring<CR>", desc = "Docstring", mode = { "n", "v" } },
    { "<leader>Ga", "<cmd>ChatGPTRun add_tests<CR>", desc = "Add Tests", mode = { "n", "v" } },
    { "<leader>Go", "<cmd>ChatGPTRun optimize_code<CR>", desc = "Optimize Code", mode = { "n", "v" } },
    { "<leader>Gs", "<cmd>ChatGPTRun summarize<CR>", desc = "Summarize", mode = { "n", "v" } },
    { "<leader>Gf", "<cmd>ChatGPTRun fix_bugs<CR>", desc = "Fix Bugs", mode = { "n", "v" } },
    { "<leader>Gx", "<cmd>ChatGPTRun explain_code<CR>", desc = "Explain Code", mode = { "n", "v" } },
    { "<leader>Gr", "<cmd>ChatGPTRun roxygen_edit<CR>", desc = "Roxygen Edit", mode = { "n", "v" } },
    {
      "<leader>Gl",
      "<cmd>ChatGPTRun code_readability_analysis<CR>",
      desc = "Code Readability Analysis",
      mode = { "n", "v" },
    },
  },
}

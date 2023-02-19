-- A completion plugin for neovim coded in Lua.
-- https://github.com/hrsh7th/nvim-cmp
--
-- nvim-cmp source for emoji
-- https://github.com/hrsh7th/cmp-emoji
--
-- A Neovim plugin to add vscode-style TailwindCSS completion to nvim-cmp
-- https://github.com/roobert/tailwindcss-colorizer-cmp.nvim

return {

  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-emoji",

    {
      "zbirenbaum/copilot-cmp",
      dependencies = {
        {
          "zbirenbaum/copilot.lua",
          cmd = "Copilot",
          event = "InsertEnter",
          config = {
            method = "getCompletionsCycling",
          },
        },
      },
      config = {
        suggestion = { enabled = false },
        panel = { enabled = false },
      },
    },

    {
      "roobert/tailwindcss-colorizer-cmp.nvim",
      dependencies = {
        {
          "NvChad/nvim-colorizer.lua",
          opts = {
            user_default_options = {
              tailwind = true,
            },
          },
        },
      },
    },
  },

  opts = function(_, opts)
    local cmp = require("cmp")

    opts.sources = cmp.config.sources(vim.list_extend(opts.sources, {
      { name = "emoji", group_index = 2 },
      { name = "copilot", group_index = 2 },
    }))

    -- Change the default keybinds
    -- Defaults: https://github.com/LazyVim/LazyVim/blob/8e84dcf85c8a73ebcf6ade6b7b77544f468f1dfa/lua/lazyvim/plugins/coding.lua#L52
    local has_words_before = function()
      if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
        return false
      end
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
    end

    opts.mapping = vim.tbl_extend("force", opts.mapping, {
      ["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
      ["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
      ["<Tab>"] = vim.schedule_wrap(function(fallback)
        if cmp.visible() and has_words_before() then
          cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
        else
          fallback()
        end
      end),
      ["<CR>"] = cmp.mapping.confirm({
        -- this is the important line
        behavior = cmp.ConfirmBehavior.Replace,
        select = false,
      }),
    })

    opts.formatting = {

      format = function(entry, item)
        local icons = require("lazyvim.config").icons.kinds
        if icons[item.kind] then
          item.kind = icons[item.kind] .. item.kind
        end

        item.menu = ({
          nvim_lsp = "[LSP]",
          nvim_lua = "[Lua]",
          buffer = "[Buf]",
          emoji = "[Emoji]",
          copilot = "[Copilot]",
        })[entry.source.name]

        return require("tailwindcss-colorizer-cmp").formatter(entry, item)
      end,
    }
  end,
}

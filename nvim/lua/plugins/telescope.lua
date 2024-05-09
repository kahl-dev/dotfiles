-- Find, Filter, Preview, Pick. All lua, all the time.
-- https://github.com/nvim-telescope/telescope.nvim

return {
  {
    "nvim-telescope/telescope.nvim",
    opts = function(_, opts)
      opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
        mappings = {
          i = {
            ["<C-j>"] = function(...)
              return require("telescope.actions").move_selection_next(...)
            end,
            ["<C-k>"] = function(...)
              return require("telescope.actions").move_selection_previous(...)
            end,
          },
        },
        path_display = { "truncate" },
        file_ignore_patterns = { ".git/", "node_modules/", "tpl/", "ce/" },
      })

      local actions_state = require("telescope.actions.state")
      local previewers = require("telescope.previewers")
      local actions = require("telescope.actions")
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local sorters = require("telescope.sorters")

      -- The Telescope picker with URL utility helper functions
      local url_utils = require("url_utils")

      -- The function to call when a URL is selected
      local function open_url(entry)
        url_utils.process_url(entry.value)
      end

      -- The Telescope picker for finding URLs in the current buffer
      _G.find_urls_in_buffer = function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local urls = {}

        -- Extract URLs from all lines in the buffer
        for _, line in ipairs(lines) do
          for url in string.gmatch(line, "(https?://[%w_.~%-/=?&]+)") do
            table.insert(urls, url)
          end
        end

        pickers
          .new({}, {
            prompt_title = "URLs in buffer",
            finder = finders.new_table({
              results = urls,
            }),
            sorter = sorters.get_fuzzy_file(),
            previewer = previewers.new_termopen_previewer({
              get_command = function(entry)
                return { "echo", entry.value }
              end,
            }),
            attach_mappings = function(prompt_bufnr)
              actions.select_default:replace(function()
                open_url(actions_state.get_selected_entry())
                actions.close(prompt_bufnr)
              end)

              return true
            end,
          })
          :find()
      end

      -- Set up key mapping
      vim.api.nvim_set_keymap(
        "n",
        "<leader>kob",
        ":lua _G.find_urls_in_buffer()<CR>",
        { desc = "Find URLs in buffer", noremap = true, silent = true }
      )

      return opts
    end,
  },
}

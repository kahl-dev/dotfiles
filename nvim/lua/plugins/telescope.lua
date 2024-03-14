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
      })

      local actions = require("telescope.actions")
      local actions_state = require("telescope.actions.state") -- This line is new
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local sorters = require("telescope.sorters")
      local previewers = require("telescope.previewers")

      -- The function to call when a URL is selected
      -- Updated open_url function to use nvim-osc52 for copying URLs to clipboard
      local function open_url(entry)
        -- Use nvim-osc52 to copy the URL to the clipboard
        require("osc52").copy(entry.value)
        vim.api.nvim_echo({ { "URL copied to clipboard", "Highlight" } }, false, {})
      end

      -- The Telescope picker
      _G.find_urls_in_buffer = function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local urls = {}

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
            attach_mappings = function(prompt_bufnr, map)
              actions.select_default:replace(function()
                open_url(actions_state.get_selected_entry(prompt_bufnr)) -- This line changed
                actions.close(prompt_bufnr)
              end)

              return true
            end,
          })
          :find()
      end

      vim.api.nvim_set_keymap(
        "n",
        "<leader>ob",
        ":lua _G.find_urls_in_buffer()<CR>",
        { desc = "Find URLs in buffer", noremap = true, silent = true }
      )

      return opts
    end,
  },
}

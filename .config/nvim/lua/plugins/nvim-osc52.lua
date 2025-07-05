return {
  "ojroques/nvim-osc52",
  config = function()
    local osc52 = require("osc52")
    osc52.setup({
      max_length = 0, -- Maximum length of selection (0 for no limit)
      silent = false, -- Disable message on successful copy
      trim = false, -- Trim surrounding whitespaces before copy
      tmux_passthrough = true, -- Enable tmux passthrough for tmux 3.5a compatibility
    })
    -- local function copy()
    --   if (vim.v.event.operator == "y" or vim.v.event.operator == "d") and vim.v.event.regname == "" then
    --     require("osc52").copy_register("")
    --   end
    -- end
    --
    -- vim.api.nvim_create_autocmd("TextYankPost", { callback = copy })

    local function copy_without_trailing_newline(mode)
      -- Capture the current selection or line depending on the mode
      local text = nil
      if mode == "line" then
        -- For normal mode, capture the current line without the trailing newline
        text = vim.fn.getline(".")
      elseif mode == "visual" then
        -- For visual mode, capture the selected text
        -- Temporarily switch to normal mode to yank the selection
        vim.cmd('normal! "vy')
        text = vim.fn.getreg("v")
        -- Remove the trailing newline character from the selection, if present
        text = text:gsub("\n$", "")
      end

      -- Use osc52 to copy the text to the system clipboard
      if text then
        osc52.copy(text)
      end
    end

    -- Set up key mappings
    vim.keymap.set("n", "<leader>y", function()
      copy_without_trailing_newline("line")
    end, { desc = "Copy line to system clipboard" })
    vim.keymap.set("v", "<leader>y", function()
      copy_without_trailing_newline("visual")
    end, { desc = "Copy selection to system clipboard" })
  end,
}

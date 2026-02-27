-- https://github.com/folke/noice.nvim

return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      cmdline = { view = "cmdline" },
      lsp = {
        hover = {
          -- Don't show a message if hover is not available
          silent = true,
        },
      },
      presets = {
        bottom_search = true,
        long_message_to_split = true,
        lsp_doc_border = true,
      },
      routes = {
        {
          filter = {
            event = "notify",
            find = "Request textDocument/inlayHint failed",
          },
          opts = { skip = true },
        },
        -- Neovim 0.11+ shell command output (unmerged PR #1098 workaround)
        { filter = { event = "msg_show", kind = "shell_out" }, view = "messages" },
        { filter = { event = "msg_show", kind = "shell_err" }, view = "messages" },
        { filter = { event = "msg_show", kind = "shell_ret" }, view = "messages" },
      },
    },
  },
}

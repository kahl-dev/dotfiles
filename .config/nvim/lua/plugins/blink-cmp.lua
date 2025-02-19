return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        -- ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
      },
      sources = {
        min_keyword_length = function(ctx)
          return ctx.trigger.kind == "manual" and 0 or 2
        end,
        providers = {
          snippets = {
            opts = {
              search_paths = { "/home/kahl/dev/snippets/lia-typo3-vscode" },
            },
          },
        },
      },
    },

    opts_extend = { "sources.providers.snippets.opts.search_paths", "keymaps" },
  },
}

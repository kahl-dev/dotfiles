-- Git status signs (Catppuccin Mocha)
th.git = th.git or {}
th.git.modified_sign  = "M"
th.git.added_sign     = "A"
th.git.deleted_sign   = "D"
th.git.untracked_sign = "?"
th.git.ignored_sign   = "I"
th.git.updated_sign   = "U"

th.git.modified  = ui.Style():fg("#89b4fa")   -- blue
th.git.added     = ui.Style():fg("#a6e3a1")   -- green
th.git.deleted   = ui.Style():fg("#f38ba8")   -- red
th.git.untracked = ui.Style():fg("#a6adc8")   -- overlay0
th.git.ignored   = ui.Style():fg("#585b70")   -- surface2
th.git.updated   = ui.Style():fg("#f9e2af")   -- yellow

require("git"):setup({ order = 1500 })

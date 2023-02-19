-- A fancy, configurable, notification manager for NeoVim
-- https://github.com/rcarriga/nvim-notify

return {
  "rcarriga/nvim-notify",
  opt = function()
    local notify = require("notify")
    notify.setup({
      background_colour = "#000000",
    })
  end,
}

// Vim undo tree visualizer
// https://github.com/simnalamburt/vim-mundo

return {
  "simnalamburt/vim-mundo",
  init = function()
    require("lazyvim.util").on_attach(function(_, buffer)
      vim.keymap.set("n", "<leader>m", "<cmd>MundoToggle<cr>", { buffer = buffer, desc = "Toggle M<Undo> Window" })
    end)
  end,
}

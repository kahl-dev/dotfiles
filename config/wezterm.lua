local wezterm = require("wezterm")

function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "Catppuccin Mocha"
	else
		return "Catppuccin Latte"
	end
end

-- return {
--   -- ...your existing config
-- }

local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.font = wezterm.font("FiraCode Nerd Font")
config.font_size = 16
config.line_height = 1.1

-- config.color_scheme = "tokyonight"
config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())

config.enable_tab_bar = true
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.adjust_window_size_when_changing_font_size = false

config.window_background_opacity = 0.75
config.macos_window_background_blur = 25

-- config.send_composed_key_when_left_alt_is_pressed = true
-- config.send_composed_key_when_right_alt_is_pressed = true
-- config.use_ime = true
config.use_dead_keys = false

config.scrollback_lines = 50000
config.window_decorations = "RESIZE"

config.keys = {
	{ key = "a", mods = "ALT|CMD", action = { SendKey = { key = "ä" } } },
	{ key = "u", mods = "ALT|CMD", action = { SendKey = { key = "ü" } } },
	{ key = "o", mods = "ALT|CMD", action = { SendKey = { key = "ö" } } },
	{ key = "s", mods = "ALT|CMD", action = { SendKey = { key = "ß" } } },
}

return config

local wezterm = require("wezterm")

local function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "Catppuccin Mocha"
	else
		return "Catppuccin Latte"
	end
end

return {
	-- Styles
	font = wezterm.font("FiraCode Nerd Font"),
	font_size = 16,
	line_height = 1.1,
	color_scheme = scheme_for_appearance(wezterm.gui.get_appearance()),
	-- color_scheme = "tokyonight"

	-- window layout
	enable_tab_bar = true,
	tab_bar_at_bottom = true,
	hide_tab_bar_if_only_one_tab = true,
	adjust_window_size_when_changing_font_size = false,
	window_background_opacity = 0.85,
	macos_window_background_blur = 25,

	-- send_composed_key_when_left_alt_is_pressed = true
	-- send_composed_key_when_right_alt_is_pressed = true
	-- use_ime = true
	use_dead_keys = false,

	scrollback_lines = 50000,
	window_decorations = "RESIZE",

	keys = {
		{ key = "a", mods = "ALT|CMD", action = { SendKey = { key = "ä" } } },
		{ key = "u", mods = "ALT|CMD", action = { SendKey = { key = "ü" } } },
		{ key = "o", mods = "ALT|CMD", action = { SendKey = { key = "ö" } } },
		{ key = "s", mods = "ALT|CMD", action = { SendKey = { key = "ß" } } },
	},
}

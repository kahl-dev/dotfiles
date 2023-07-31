-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = "tokyonight"
config.window_background_opacity = 0.9
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true

wezterm.font = wezterm.font("FireCode Nerd Font Mono")
config.font_size = 20

config.scrollback_lines = 50000
config.window_decorations = "RESIZE"

-- and finally, return the configuration to wezterm
return config

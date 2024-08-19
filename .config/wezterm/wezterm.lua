local wezterm = require("wezterm")

-- https://www.youtube.com/watch?v=I3ipo8NxsjY
-- https://github.com/theopn/dotfiles/blob/main/wezterm/wezterm.lua
-- https://wezfurlong.org/wezterm/config/lua/general.html

local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- config.color_scheme = "Tokyo Night"
config.color_scheme = "Catppuccin Mocha"

config.font = wezterm.font({ family = "Monaspace Argon" })
config.font_rules = {
	{
		italic = true,
		font = wezterm.font({
			family = "Monaspace Radon",
			style = "Italic",
		}),
	},
	{
		intensity = "Bold",
		font = wezterm.font({
			family = "Monaspace Argon",
			weight = "Bold",
		}),
	},
	{
		intensity = "Bold",
		italic = true,
		font = wezterm.font({
			family = "Monaspace Radon",
			weight = "Bold",
			style = "Italic",
		}),
	},
}

-- config.font = wezterm.font_with_fallback({
-- 	{ family = "FiraCode Nerd Font" },
-- 	{ family = "JetBrains Mono" },
-- 	{ family = "Hack Nerd Font" },
-- })

config.font_size = 18
config.line_height = 1.1
config.adjust_window_size_when_changing_font_size = false

config.term = "xterm-256color"
config.window_background_opacity = 0.8
config.macos_window_background_blur = 90
config.window_decorations = "RESIZE"
config.window_close_confirmation = "AlwaysPrompt"
config.scrollback_lines = 3000
config.default_workspace = "main"

config.use_dead_keys = false

-- Dim inactive panes
config.inactive_pane_hsb = {
	saturation = 0.24,
	brightness = 0.5,
}

-- Tab bar
config.use_fancy_tab_bar = false
config.status_update_interval = 1000
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = false
wezterm.on("update-status", function(window, pane)
	-- Workspace name
	local stat = window:active_workspace()
	local stat_color = "#f7768e"
	-- It's a little silly to have workspace name all the time
	-- Utilize this to display LDR or current key table name
	if window:active_key_table() then
		stat = window:active_key_table()
		stat_color = "#7dcfff"
	end
	if window:leader_is_active() then
		stat = "LDR"
		stat_color = "#bb9af7"
	end

	local basename = function(s)
		-- Nothing a little regex can't fix
		return string.gsub(s, "(.*[/\\])(.*)", "%2")
	end

	-- Current working directory
	local cwd = pane:get_current_working_dir()
	if cwd then
		if type(cwd) == "userdata" then
			-- Wezterm introduced the URL object in 20240127-113634-bbcac864
			cwd = basename(cwd.file_path)
		else
			-- 20230712-072601-f4abf8fd or earlier version
			cwd = basename(cwd)
		end
	else
		cwd = ""
	end

	-- Current command
	local cmd = pane:get_foreground_process_name()
	-- CWD and CMD could be nil (e.g. viewing log using Ctrl-Alt-l)
	cmd = cmd and basename(cmd) or ""

	-- Left status (left of the tab line)
	window:set_left_status(wezterm.format({
		-- { Foreground = { Color = stat_color } },
		-- { Text = "  " },
		-- { Text = wezterm.nerdfonts.oct_table .. "  " .. stat },
		-- { Text = " |" },
	}))

	-- Right status
	window:set_right_status(wezterm.format({
		-- Wezterm has a built-in nerd fonts
		-- https://wezfurlong.org/wezterm/config/lua/wezterm/nerdfonts.html
		{ Text = wezterm.nerdfonts.md_folder .. "  " .. cwd },
		"ResetAttributes",
		{ Text = "  " },
	}))
end)

config.enable_tab_bar = true
config.window_padding = {
	left = "1cell",
	right = "1cell",
	top = "0.2cell",
	bottom = "0.2cell",
}

return config

-- -- send_composed_key_when_left_alt_is_pressed = true
-- -- send_composed_key_when_right_alt_is_pressed = true
-- -- use_ime = true
-- use_dead_keys = false,
--
-- keys = {
-- 	{ key = "a", mods = "ALT|CMD", action = { SendKey = { key = "ä" } } },
-- 	{ key = "u", mods = "ALT|CMD", action = { SendKey = { key = "ü" } } },
-- 	{ key = "o", mods = "ALT|CMD", action = { SendKey = { key = "ö" } } },
-- 	{ key = "s", mods = "ALT|CMD", action = { SendKey = { key = "ß" } } },
-- },

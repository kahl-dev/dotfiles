-- https://github.com/norcalli/nvim-colorizer.lua

local status_ok, colorizer = pcall(require, "colorizer")
if not status_ok then
	return
end

colorizer.setup({
	"scss",
	"css",
	"html",
	"vue",
}, {
	RGB = true,
	RRGGBB = true,
	names = true,
	RRGGBBAA = true,
	rgb_fn = true,
	hsl_fn = true,
	css = true,
	css_fn = true,
	mode = "background",
})

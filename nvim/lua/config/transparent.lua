-- https://github.com/xiyaowong/nvim-transparent

local status_ok, transparent = pcall(require, "transparent")
if not status_ok then
	return
end

transparent.setup({
	enable = true, -- boolean: enable transparent
	extra_groups = "all",
	-- extra_groups = { -- table/string: additional groups that should be clear
	-- 	-- In particular, when you set it to 'all', that means all avaliable groups
	--
	-- 	"CursorLine",
	--
	-- 	-- example of akinsho/nvim-bufferline.lua
	-- 	"BufferLineTabClose",
	-- 	"BufferlineBufferSelected",
	-- 	"BufferLineFill",
	-- 	"BufferLineBackground",
	-- 	"BufferLineSeparator",
	-- 	"BufferLineIndicatorSelected",
	--
	-- 	"NvimTreeNormal",
	-- 	"NvimTreeStatuslineNc",
	--
	-- 	"lualine_c_normal",
	--
	-- 	"TelescopeNormal",
	-- 	"TelescopeBorder",
	-- },
	exclude = {
		"CmpDocumentationBorder",
		"ColorColumn",
		"Comment",
		"CopilotSuggestion",
		"Cursor",
		"CursorLine",
		"DefinitionBorder",
		"DiagnosticError",
		"DiagnosticHint",
		"DiagnosticInfo",
		"DiagnosticWarn",
		"FinderSpinnerBorder",
		"FloatBorder",
		"GitSignsAdd",
		"GitSignsAddLn",
		"GitSignsChange",
		"GitSignsChangeLn",
		"GitSignsDelete",
		"GitSignsDeleteLn",
		"IndentBlankLineIndent1",
		"IndentBlanklineIndent2",
		"IndentBlanklineIndent3",
		"IndentBlanklineIndent4",
		"IndentBlanklineIndent5",
		"IndentBlanklineIndent6",
		"LSOutlinePreviewBorder",
		"LspFloatWinBorder",
		"LspSagaCodeActionBorder",
		"LspSagaDiagnosticBorder",
		"LspSagaHoverBorder",
		"LspSagaLspFinderBorder",
		"LspSagaRenameBorder",
		"LspSagaSignatureHelpBorder",
		"NeotestBorder",
		"NotifyDEBUGBorder",
		"NotifyERRORBorder",
		"NotifyINFOBorder",
		"NotifyTRACEBorder",
		"NotifyWARNBorder",
		"NvimSeparator",
		"OutlineDetail",
		"OutlineIndentEvn",
		"ScrollbarCursor",
		"ScrollbarHandle",
		"ScrollbarSearch",
		"Search",
		"TelescopeBorder",
		"TelescopePreviewBorder",
		"TelescopePromptBorder",
		"TelescopeResultsBorder",
		"TelescopeSelection",
		"TodoBgFix",
		"TodoBgHACK",
		"TodoBgNOTE",
		"TodoBgPERF",
		"TodoBgTODO",
		"TodoBgWARN",
		"Visual",
		"WinSeparator",
		"lualine_a_command",
		"lualine_a_insert",
		"lualine_a_normal",
		"lualine_a_visual",
	}, -- table: groups you don't want to clear
})

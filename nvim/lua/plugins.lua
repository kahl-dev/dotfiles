local M = {}

function M.setup()
	-- Indicate first time installation
	local packer_bootstrap = false

	-- packer.nvim configuration
	local conf = {
		enable = true, -- enable profiling via :PackerCompile profile=true
		threshold = 0, -- the amount in ms that a plugins load time must be over for it to be included in the profile
		display = {
			open_fn = function()
				return require("packer.util").float({ border = "rounded" })
			end,
		},
	}

	-- Check if packer.nvim is installed
	-- Run PackerCompile if there are changes in this file
	local function packer_init()
		local fn = vim.fn
		local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
		if fn.empty(fn.glob(install_path)) > 0 then
			packer_bootstrap = fn.system({
				"git",
				"clone",
				"--depth",
				"1",
				"https://github.com/wbthomason/packer.nvim",
				install_path,
			})
			vim.cmd([[packadd packer.nvim]])
		end
		vim.cmd("autocmd BufWritePost plugins.lua source <afile> | PackerCompile")
	end

	-- returns the require for use in `config` parameter of packer's use
	-- expects the name of the config file
	function get_config(name)
		return string.format('require("config/%s")', name)
	end

	-- Plugins
	local function plugins(use)
		-- actual plugins list
		use("wbthomason/packer.nvim")

		-- Startup screen
		use({
			"goolord/alpha-nvim",
			config = function()
				require("config.alpha").setup()
			end,
		})

		-- Telescope
		-- https://github.com/nvim-telescope/telescope.nvim
		use({
			"nvim-telescope/telescope.nvim",
			requires = { { "nvim-lua/popup.nvim" }, { "nvim-lua/plenary.nvim" } },
			config = get_config("telescope"),
		})

		use({ "nvim-telescope/telescope-fzf-native.nvim", run = "make" })
		use("cljoly/telescope-repo.nvim")

		-- use {"jvgrootveld/telescope-zoxide"}
		-- use {"crispgm/telescope-heading.nvim"}
		-- use {"nvim-telescope/telescope-symbols.nvim"}
		-- use {"nvim-telescope/telescope-file-browser.nvim"}
		-- use {"nvim-telescope/telescope-fzf-native.nvim", run = "make"}

		use({ "numToStr/Comment.nvim", config = get_config("comment") })
		use({ "folke/which-key.nvim", config = get_config("whichkey") })
		use({ "kyazdani42/nvim-tree.lua", config = get_config("nvim-tree") })

		use({ "windwp/nvim-autopairs", config = get_config("autopairs") })
		use("kyazdani42/nvim-web-devicons")
		use({ "akinsho/bufferline.nvim", config = get_config("bufferline") })
		use("moll/vim-bbye")
		use({ "nvim-lualine/lualine.nvim", config = get_config("lualine") })
		use({ "akinsho/toggleterm.nvim", config = get_config("toggleterm") })
		use({ "ahmedkhalf/project.nvim", config = get_config("project") })
		use({ "lewis6991/impatient.nvim", config = get_config("impatient") })
		use("lukas-reineke/indent-blankline.nvim")
		use("antoinemadec/FixCursorHold.nvim") -- This is needed to fix lsp doc highlight

		-- cmp plugins
		use({
			"hrsh7th/nvim-cmp",
			requires = {
				{ "hrsh7th/cmp-nvim-lsp" },
				{ "hrsh7th/cmp-buffer" },
				{ "hrsh7th/cmp-path" },
				{ "hrsh7th/cmp-cmdline" },
				{ "saadparwaiz1/cmp_luasnip" },
				{ "hrsh7th/cmp-copilot" },
				--[[ { "tzachar/cmp-tabnine" }, ]]
				{ "lukas-reineke/cmp-rg" },
			},
			config = get_config("cmp"),
		})

		--[[ use({ ]]
		--[[ 	"tzachar/cmp-tabnine", ]]
		--[[ 	run = "./install.sh", ]]
		--[[ 	requires = "hrsh7th/nvim-cmp", ]]
		--[[ }) ]]

		-- snippets
		use("L3MON4D3/LuaSnip") --snippet engine
		use("rafamadriz/friendly-snippets") -- a bunch of snippets to use

		-- use {
		--     "hrsh7th/nvim-cmp",
		--     requires = {
		--         {"hrsh7th/cmp-nvim-lsp"}, {"hrsh7th/cmp-buffer"}, {"hrsh7th/cmp-path"},
		--         {"hrsh7th/cmp-cmdline"}, {"hrsh7th/cmp-vsnip"},
		--         {"f3fora/cmp-spell", {"hrsh7th/cmp-calc"}}
		--     },
		--     config = get_config("cmp")
		-- }
		-- use {"hrsh7th/vim-vsnip", config = get_config("vsnip")}
		-- use {"rafamadriz/friendly-snippets", requires = {{"hrsh7th/vim-vsnip"}}}

		-- LSP
		use({ "neovim/nvim-lspconfig", config = get_config("lsp") }) -- enable LSP
		use("williamboman/nvim-lsp-installer") -- simple to use language server installer
		use("tamago324/nlsp-settings.nvim") -- language server settings defined in json for
		use("jose-elias-alvarez/null-ls.nvim") -- for formatters and linters

		-- COLORSCHEMES
		-- https://alpha2phi.medium.com/12-neovim-themes-with-tree-sitter-support-8be320b683a4
		-- https://alpha2phi.medium.com/12-neovim-themes-with-tree-sitter-support-8be320b683a4
		-- use "lunarvim/colorschemes" -- A bunch of colorschemes you can try out
		-- use("lunarvim/darkplus.nvim")
		-- use("RRethy/nvim-base16")
		-- use({
		-- 	"folke/tokyonight.nvim",
		-- 	requires = { { "xiyaowong/nvim-transparent" } },
		-- 	config = get_config("tokyonight"),
		-- })

		use({
			"mhartington/oceanic-next",
			requires = { { "xiyaowong/nvim-transparent" } },
			config = get_config("oceanicnext"),
		})

		-- VIMSCRIPT PLUGINS

		use({ "airblade/vim-rooter", config = get_config("vim-rooter") })
		use({ "justinmk/vim-sneak", config = get_config("vim-sneak") })
		use("unblevable/quick-scope")
		use("tpope/vim-surround")
		use("tpope/vim-eunuch")
		use("tpope/vim-repeat")

		use("christoomey/vim-tmux-navigator")
		-- @replace with this lua one
		-- use {"numToStr/Navigator.nvim", config = get_config("navigator")}

		-- Treesitter
		--
		use({
			"nvim-treesitter/nvim-treesitter",
			run = ":TSUpdate",
			config = get_config("treesitter"),
		})
		use("JoosepAlviste/nvim-ts-context-commentstring")
		use("p00f/nvim-ts-rainbow")

		-- Git
		use("lewis6991/gitsigns.nvim")
		use("tpope/vim-fugitive")
		use("tpope/vim-rhubarb")
		use({
			"shumphrey/fugitive-gitlab.vim",
			config = function()
				vim.g["fugitive_gitlab_domains"] = { "https://gitlab.louis-net.de" }
			end,
		})
		use("f-person/git-blame.nvim")
		use({
			"yardnsm/vim-import-cost",
			run = "npm install --production",
			config = get_config("vim-import-cost"),
		})

		--
		--
		-- use {
		--     "nvim-lualine/lualine.nvim",
		--     config = get_config("lualine"),
		--     event = "VimEnter",
		--     requires = {"kyazdani42/nvim-web-devicons", opt = true}
		-- }
		--
		-- use {
		--     "norcalli/nvim-colorizer.lua",
		--     event = "BufReadPre",
		--     config = get_config("colorizer")
		-- }
		--
		--
		-- use {
		--     "nvim-treesitter/nvim-treesitter",
		--     config = get_config("treesitter"),
		--     run = ":TSUpdate"
		-- }
		--
		-- use "nvim-treesitter/nvim-treesitter-textobjects"
		--
		--
		-- use {
		--     "mhartington/formatter.nvim",
		--     event = "BufWritePre",
		--     config = get_config("formatter")
		-- }
		--
		-- -- requirement for Neogit
		-- use {
		--     "sindrets/diffview.nvim",
		--     cmd = {
		--         "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles",
		--         "DiffviewFocusFiles"
		--     },
		--     config = get_config("diffview")
		-- }
		--
		-- use {
		--     "TimUntersberger/neogit",
		--     requires = {"nvim-lua/plenary.nvim"},
		--     cmd = "Neogit",
		--     config = get_config("neogit")
		-- }
		--
		-- use {"f-person/git-blame.nvim", config = get_config("git-blame")}
		--
		-- use {
		--     "lewis6991/gitsigns.nvim",
		--     requires = {"nvim-lua/plenary.nvim"},
		--     event = "BufReadPre",
		--     config = get_config("gitsigns")
		-- }
		--
		-- use {
		--     "kevinhwang91/nvim-bqf",
		--     requires = {{"junegunn/fzf", module = "nvim-bqf"}}
		-- }
		--
		-- use {
		--     "akinsho/nvim-bufferline.lua",
		--     requires = "kyazdani42/nvim-web-devicons",
		--     event = "BufReadPre",
		--     config = get_config("bufferline")
		-- }
		--
		-- use "famiu/bufdelete.nvim"
		--
		-- use {"neovim/nvim-lspconfig", config = get_config("lsp")}
		--
		-- use {"ray-x/lsp_signature.nvim", requires = {{"neovim/nvim-lspconfig"}}}
		--
		-- use {"onsails/lspkind-nvim", requires = {{"famiu/bufdelete.nvim"}}}
		--
		-- use {
		--     "simrat39/symbols-outline.nvim",
		--     cmd = {"SymbolsOutline"},
		--     config = get_config("symbols")
		-- }
		--
		-- use {
		--     "lukas-reineke/indent-blankline.nvim",
		--     event = "BufReadPre",
		--     config = [[require("config/indent-blankline")]]
		-- }
		--
		-- use {
		--     "akinsho/nvim-toggleterm.lua",
		--     keys = {"<C-y>", "<leader>fl", "<leader>gt"},
		--     config = get_config("toggleterm")
		-- }
		--
		-- use {
		--     "folke/trouble.nvim",
		--     requires = "kyazdani42/nvim-web-devicons",
		--     cmd = {"TroubleToggle", "Trouble"},
		--     config = get_config("trouble")
		-- }
		--
		-- use {
		--     "folke/todo-comments.nvim",
		--     requires = "nvim-lua/plenary.nvim",
		--     cmd = {"TodoTrouble", "TodoTelescope"},
		--     event = "BufReadPost",
		--     config = get_config("todo")
		-- }
		--
		-- use {"ahmedkhalf/project.nvim", config = get_config("project")}
		--
		-- use "ironhouzi/starlite-nvim"
		--
		--
		-- use "junegunn/vim-easy-align" -- no lua alternative
		--
		-- use {"rhysd/vim-grammarous", cmd = "GrammarousCheck"}
		--
		-- use {"RRethy/vim-illuminate", event = "CursorHold"}
		--
		-- use {
		--     "ptzz/lf.vim",
		--     requires = "voldikss/vim-floaterm",
		--     config = get_config("lf")
		-- }
		--
		-- use {"EdenEast/nightfox.nvim", config = get_config("nightfox")}
		--
		-- use {
		--     "karb94/neoscroll.nvim",
		--     keys = {"<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-e>", "zt", "zz", "zb"},
		--     config = get_config("neoscroll")
		-- }
		--
		-- use {
		--     "ThePrimeagen/harpoon",
		--     requires = {"nvim-lua/plenary.nvim"},
		--     config = get_config("harpoon")
		-- }
		--
		-- use {"folke/zen-mode.nvim", cmd = "ZenMode", config = get_config("zen-mode")}
		--
		-- use {"folke/twilight.nvim", config = get_config("twilight")}
		--
		-- use {"tweekmonster/startuptime.vim"}
		--
		-- use {"ggandor/lightspeed.nvim", event = "BufReadPre"}
		--
		-- use {"cuducos/yaml.nvim", ft = {"yaml"}}
		--
		-- use {"ray-x/go.nvim", config = get_config("go")}
		--
		-- use {"LudoPinelli/comment-box.nvim", config = get_config("comment-box")}
		--
		-- use {"rcarriga/nvim-notify", config = get_config("notify")}
		--
		-- use {"echasnovski/mini.nvim", branch = "stable", config = get_config("mini")}
		--
		-- use {
		--     "https://gitlab.com/yorickpeterse/nvim-window.git",
		--     config = get_config("nvim-window")
		-- }
		--
		-- -- TODO: ????
		-- -- https://github.com/glepnir/lspsaga.nvim
		-- -- use 'glepnir/lspsaga.nvim

		-- Automatically set up your configuration after cloning packer.nvim
		-- Put this at the end after all plugins
		if packer_bootstrap then
			print("Restart Neovim required after installation!")
			require("packer").sync()
		end
	end

	packer_init()

	local packer = require("packer")
	packer.init(conf)
	packer.startup(plugins)
end

return M

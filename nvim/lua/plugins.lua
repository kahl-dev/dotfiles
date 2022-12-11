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
	local function get_config(name)
		return string.format('require("config/%s")', name)
	end

	-- Plugins
	local function plugins(use)
		-- actual plugins list
		use("wbthomason/packer.nvim")

		-- Speed neovim startup time
		-- https://github.com/lewis6991/impatient.nvim
		use({
			"lewis6991/impatient.nvim",
			config = get_config("impatient"),
		})

		-- Icon set
		-- https://github.com/kyazdani42/nvim-web-devicons
		use("kyazdani42/nvim-web-devicons")

		-- Color theme
		-- https://github.com/mhartington/oceanic-next
		use({
			"mhartington/oceanic-next",
			config = get_config("oceanicnext"),
		})

    -- https://github.com/folke/tokyonight.nvim
		use({
			"folke/tokyonight.nvim",
			config = get_config("tokyonight"),
		})

		-- Add transparent background
		-- https://github.com/xiyaowong/nvim-transparent
		use({
			"xiyaowong/nvim-transparent",
			config = get_config("transparent"),
		})

		-- Code Colorizerlsp
		-- https://github.com/norcalli/nvim-colorizer.lua
		use({
			"norcalli/nvim-colorizer.lua",
			config = get_config("colorizer"),
		})

		-- Autopair
		-- https://github.com/windwp/nvim-autopairs
		use({
			"windwp/nvim-autopairs",
			config = get_config("autopairs"),
		})

		-- Better buffer handling
		-- https://github.com/moll/vim-bbye
		use("moll/vim-bbye")

		-- Indentation guide
		-- https://github.com/lukas-reineke/indent-blankline.nvim
		use({
			"lukas-reineke/indent-blankline.nvim",
			config = get_config("indent-blankline"),
		})

		-- highlight same word under cursor
		-- https://github.com/RRethy/vim-illuminate
		use({ "RRethy/vim-illuminate", event = "CursorHold" })

		-- bufferline
		-- https://github.com/akinsho/bufferline.nvim
		use({
			"akinsho/bufferline.nvim",
			requires = "kyazdani42/nvim-web-devicons",
			config = get_config("bufferline"),
		})

		-- lualine
		-- https://github.com/nvim-lualine/lualine.nvim
		use({
			"nvim-lualine/lualine.nvim",
			requires = { "kyazdani42/nvim-web-devicons", opt = true },
			config = get_config("lualine"),
		})

		-- startup screen
		-- https://github.com/goolord/alpha-nvim
		use({
			"goolord/alpha-nvim",
			requires = { "kyazdani42/nvim-web-devicons" },
			config = get_config("alpha"),
		})

		-- bindings preview
		-- https://github.com/folke/which-key.nvim
		use({
			"folke/which-key.nvim",
			config = get_config("whichkey"),
		})

		-- commenting
		-- https://github.com/numToStr/Comment.nvim
		use({
			"numToStr/Comment.nvim",
			config = get_config("comment"),
		})

		-- better filetree
		-- https://github.com/kyazdani42/nvim-tree.lua
		use({
			"kyazdani42/nvim-tree.lua",
			requires = {
				"kyazdani42/nvim-web-devicons", -- optional, for file icons
			},
			config = get_config("nvim-tree"),
		})

		-- Show undo history
		-- https://github.com/simnalamburt/vim-mundo
		use("simnalamburt/vim-mundo")

		-- telescope
		-- https://github.com/nvim-telescope/telescope.nvim
		use({
			"nvim-telescope/telescope.nvim",
			requires = { { "nvim-lua/popup.nvim" }, { "nvim-lua/plenary.nvim" } },
			config = get_config("telescope"),
		})
		use({ "nvim-telescope/telescope-fzf-native.nvim", run = "make" })
		use("cljoly/telescope-repo.nvim")


		-- LSP

		-- use() -- for formatters and linters
		--   use 'MunifTanjim/prettier.nvim'

		use({
			"neovim/nvim-lspconfig",
			requires = {
				{ "williamboman/mason.nvim" },
				{ "williamboman/mason-lspconfig.nvim" },
				{ "jose-elias-alvarez/null-ls.nvim" },
				{ "jayp0521/mason-null-ls.nvim" },
			},
			config = function()
				require("config.lsp").setup()
			end,
		})

		--[[ use("tamago324/nlsp-settings.nvim") -- language server settings defined in json for ]]

		-- cmp plugins
		use({
			"hrsh7th/nvim-cmp",
			requires = {
				{ "hrsh7th/cmp-nvim-lsp" },
				{ "hrsh7th/cmp-buffer" },
				{ "hrsh7th/cmp-path" },
				{ "hrsh7th/cmp-cmdline" },
				{ "f3fora/cmp-spell" },
				{
					"saadparwaiz1/cmp_luasnip",
					requires = {
						{ "L3MON4D3/LuaSnip" },
						{ "rafamadriz/friendly-snippets" },
					},
				},
			},
			config = get_config("cmp"),
		})

	  use({ "github/copilot.vim" , config = get_config("copilot")})

		-- VIMSCRIPT PLUGINS

		use({ "airblade/vim-rooter", config = get_config("vim-rooter") })
		-- use({ "justinmk/vim-sneak", config = get_config("vim-sneak") })
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
		use("nvim-treesitter/nvim-treesitter-context")
		use("nvim-treesitter/nvim-treesitter-textobjects")
		use("p00f/nvim-ts-rainbow")

		-- Git
		use({
			"lewis6991/gitsigns.nvim",
			requires = { "nvim-lua/plenary.nvim" },
			event = "BufReadPre",
			config = get_config("gitsigns"),
		})

		use("tpope/vim-fugitive")
		use("tpope/vim-rhubarb")
		use({
			"shumphrey/fugitive-gitlab.vim",
			config = function()
				vim.g["fugitive_gitlab_domains"] = { "https://gitlab.louis-net.de" }
			end,
		})

		-- Tool to show git blame
		-- https://github.com/f-person/git-blame.nvim
		use({ "f-person/git-blame.nvim", config = get_config("git-blame") })

		-- Git diff merge tool
		use({
			"sindrets/diffview.nvim",
			requires = "nvim-lua/plenary.nvim",
			config = get_config("diffview"),
		})

		--[[
    -- integrate terminal
    -- https://github.com/akinsho/toggleterm.nvim
		use({
      "akinsho/toggleterm.nvim",
      config = get_config("toggleterm")
    })
    ]]

		--[[
    -- creat project
    -- https://github.com/ahmedkhalf/project.nvim
		use({
      "ahmedkhalf/project.nvim",
      config = get_config("project")
    })
    ]]

		-- use {
		--     "folke/todo-comments.nvim",
		--     requires = "nvim-lua/plenary.nvim",
		--     cmd = {"TodoTrouble", "TodoTelescope"},
		--     event = "BufReadPost",
		--     config = get_config("todo")
		-- }
		--
		-- use {
		--     "ThePrimeagen/harpoon",
		--     requires = {"nvim-lua/plenary.nvim"},
		--     config = get_config("harpoon")
		-- }

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

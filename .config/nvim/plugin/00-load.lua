vim.pack.add({
	-- lsp & formatting
	"https://github.com/stevearc/conform.nvim",
	"https://github.com/neovim/nvim-lspconfig",

	-- QoL
	"https://github.com/stevearc/oil.nvim",
	"https://github.com/nvim-mini/mini.icons",

	-- colorschemes
	"https://github.com/irohn/koda",
	"https://github.com/Aejkatappaja/sora",
	"https://github.com/omacom-io/lumon.nvim",
	"https://github.com/rebelot/kanagawa.nvim",
})

require("mini.icons").setup()

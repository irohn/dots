return {
	"conform-nvim",
	lazy = true,
	init = function()
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
	config = function()
		local cmd = require("nix.adapters.conform").cmd

		require("conform").setup({
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				shell = { "shfmt" },
				nix = { "alejandra" },
			},
			default_format_opts = {
				lsp_format = "fallback",
			},
			format_on_save = { timeout_ms = 500 },
			formatters = {
				shfmt = {
					append_args = { "-i", "2" },
					command = cmd("shfmt", "shfmt"),
				},
				alejandra = {
					command = cmd("alejandra", "alejandra"),
				},
				stylua = {
					command = cmd("stylua", "stylua"),
				},
				black = {
					command = cmd("python3Packages.black", "black"),
				},
				isort = {
					command = cmd("python3Packages.isort", "isort"),
				},
			},
		})

		vim.keymap.set("n", "<c-f>", function()
			require("conform").format({ async = true })
		end)
	end,
}

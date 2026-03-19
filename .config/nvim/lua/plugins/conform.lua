return {
	"conform-nvim",
	provider = "nix",
	lazy = true,
	init = function()
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
	config = function()
		local nix_util = require("nix.util")

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
					command = nix_util.command("shfmt"),
				},
				alejandra = {
					command = nix_util.command("alejandra"),
				},
				stylua = {
					command = nix_util.command("stylua"),
				},
				black = {
					command = nix_util.command({
						attr = "python3Packages.black",
						bin = "black",
					}),
				},
				isort = {
					command = nix_util.command({
						attr = "python3Packages.isort",
						bin = "isort",
					}),
				},
			},
		})

		vim.keymap.set("n", "<c-f>", function()
			require("conform").format({ async = true })
		end)
	end,
}

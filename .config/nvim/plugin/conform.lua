require("conform").setup({
	formatters_by_ft = {
		c = { "clang-format" },
		go = { "gofmt", "goimports" },
		json = { "jq" },
		lua = { "stylua" },
		nix = { "alejandra" },
		python = { "isort", "black" },
		rust = { "rustfmt" },
		shell = { "shfmt" },
		yaml = { "yq" },
	},
	default_format_opts = {
		lsp_format = "fallback",
	},
})

vim.keymap.set("n", "<c-f>", function()
	require("conform").format({ async = true })
end, { silent = true })

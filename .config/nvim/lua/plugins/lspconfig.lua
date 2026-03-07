return {
	"nvim-lspconfig",
	config = function()
		require("nix").adapters.lsp.enable({
			lua_ls = "lua-language-server",
			pyright = {
				attr = "pyright",
				bin = "pyright-langserver",
				args = { "--stdio" },
			},
		})
	end,
}

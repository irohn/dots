return {
	"nvim-lspconfig",
	provider = "nix",
	config = function()
		local nix_util = require("nix.util")

		local servers = {
			{
				name = "lua_ls",
				command = "lua-language-server",
			},
			{
				name = "pyright",
				command = {
					attr = "pyright",
					bin = "pyright-langserver",
					args = { "--stdio" },
				},
			},
		}

		for _, server in ipairs(servers) do
			nix_util.command(server.command, function(cmd)
				vim.lsp.config(server.name, { cmd = type(cmd) == "table" and cmd or { cmd } })
				vim.lsp.enable(server.name)
			end)
		end
	end,
}

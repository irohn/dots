return {
	"lualine-nvim",
	provider = "nix",
	async = false,
	config = function()
		require("lualine").setup({
			options = {
				-- section_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				component_separators = { left = "|", right = "|" },
			},
		})
	end,
}

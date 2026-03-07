return {
	"lualine-nvim",
	async = false,
	config = function()
		require("lualine").setup({
			options = {
				section_separators = { left = "", right = "" },
				component_separators = { left = "|", right = "|" },
			},
		})
	end,
}

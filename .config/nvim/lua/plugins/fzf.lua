return {
	"fzf-lua",
	async = false,
	dependencies = {
		"nvim-web-devicons",
	},
	config = function()
		require("fzf-lua").setup()
		vim.keymap.set("n", "<leader>/", require("fzf-lua").blines)
		vim.keymap.set("n", "<leader>ff", require("fzf-lua").files)
		vim.keymap.set("n", "<leader>fb", require("fzf-lua").buffers)
		vim.keymap.set("n", "<leader>fg", require("fzf-lua").live_grep_native)
		vim.keymap.set("n", "<leader>ft", require("fzf-lua").tabs)
	end,
}

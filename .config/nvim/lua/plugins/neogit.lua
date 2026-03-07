return {
	"neogit",
	dependencies = {
		"plenary-nvim",
		"codediff-nvim",
		"fzf-lua",
	},
	config = function()
		vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Open Neogit UI" })
	end,
}

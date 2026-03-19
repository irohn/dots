return {
	"neogit",
	provider = "nix",
	dependencies = {
		{ "plenary-nvim", provider = "nix" },
		{ "codediff-nvim", provider = "nix" },
		{ "fzf-lua", provider = "nix" },
	},
	config = function()
		vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Open Neogit UI" })
	end,
}

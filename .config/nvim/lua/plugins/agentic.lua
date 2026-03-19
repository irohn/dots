return {
	"https://github.com/carlos-algms/agentic.nvim",
	config = function()
		local nix_util = require("nix.util")

		require("agentic").setup({
			provider = "codex-acp",
			acp_providers = {
				["codex-acp"] = {
					command = nix_util.command("codex-acp"),
				},
			},
		})

		vim.keymap.set({ "n" }, "<leader>aa", function()
			require("agentic").toggle()
		end, { desc = "Toggle Agentic Chat" })

		vim.keymap.set({ "v" }, "<leader>ae", function()
			require("agentic").add_selection_or_file_to_context()
		end, { desc = "Add file or selection to Agentic to Context" })
	end,
}

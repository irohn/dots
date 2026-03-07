return {
	"agentic.nvim",
	github = "carlos-algms/agentic.nvim",
	config = function()
		require("agentic").setup({
			provider = "opencode-acp",
		})

		vim.keymap.set({ "n" }, "<leader>aa", function()
			require("agentic").toggle()
		end, { desc = "Toggle Agentic Chat" })

		vim.keymap.set({ "v" }, "<leader>ae", function()
			require("agentic").add_selection_or_file_to_context()
		end, { desc = "Add file or selection to Agentic to Context" })
	end,
}

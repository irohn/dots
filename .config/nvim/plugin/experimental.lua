-- new ui
require("vim._core.ui2").enable({})

-- undotree built-in plugin
vim.keymap.set("n", "<leader>u", function()
	if not vim.g.loaded_undotree then
		vim.cmd.packadd("undotree")
	end
	vim.cmd.Undotree()
end)

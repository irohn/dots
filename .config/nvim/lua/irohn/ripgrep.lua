local M = {}

M.is_available = vim.fn.executable("rg") == 1

function M.setup()
	if not M.is_available then
		return false
	end

	vim.o.grepprg = "rg --vimgrep --hidden --glob !.git"
	vim.o.grepformat = "%f:%l:%c:%m"

	-- Open the quickfix list automatically after :grep, only if there are
	-- results. `cwindow` is the canonical pairing with `:silent grep!`.
	vim.api.nvim_create_autocmd("QuickFixCmdPost", {
		group = vim.api.nvim_create_augroup("irohn/ripgrep-quickfix", { clear = true }),
		pattern = "grep",
		command = "cwindow",
	})

	return true
end

return M

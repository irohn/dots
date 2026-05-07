local terminal = {
	buf = nil,
	win = nil,
}

vim.api.nvim_set_hl(0, "TerminalWindow", {
	bg = "#1a1d24",
})

local function terminal_height()
	return math.max(10, math.floor(vim.o.lines / 3))
end

local function is_valid_buf(buf)
	return buf and vim.api.nvim_buf_is_valid(buf)
end

local function is_valid_win(win)
	return win and vim.api.nvim_win_is_valid(win)
end

local function open_terminal()
	vim.cmd("botright split")
	vim.api.nvim_win_set_height(0, terminal_height())
	terminal.win = vim.api.nvim_get_current_win()
	vim.wo[terminal.win].winhighlight = "Normal:TerminalWindow,NormalNC:TerminalWindow"

	if is_valid_buf(terminal.buf) then
		vim.api.nvim_win_set_buf(terminal.win, terminal.buf)
	else
		vim.cmd.terminal()
		terminal.buf = vim.api.nvim_get_current_buf()
		vim.bo[terminal.buf].bufhidden = "hide"
	end

	vim.cmd.startinsert()
end

local function toggle_terminal()
	if is_valid_win(terminal.win) then
		vim.api.nvim_win_close(terminal.win, true)
		terminal.win = nil
		return
	end

	open_terminal()
end

vim.keymap.set({ "n", "t" }, "<C-x>", toggle_terminal, {
	desc = "Toggle terminal",
})

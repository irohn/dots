vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.o.cursorline = true
vim.o.undofile = true
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.virtualedit = "block"
vim.o.wildmenu = true
vim.o.wildmode = "longest:full,full"
vim.opt.wildignore:append({ "./", "../" })
vim.opt.path:append({ "**" })

vim.keymap.set("n", "<leader>/", function()
	local scope = "%"
	local cmd = (":vimgrep // %s | copen"):format(scope)
	vim.api.nvim_feedkeys(
		vim.api.nvim_replace_termcodes(cmd .. string.rep("<Left>", #scope + 10), true, false, true),
		"n",
		true
	)
end, { silent = true })
vim.keymap.set("n", "<leader>fg", function()
	local scope = "**/* **/.*" -- also search dotfiles recursivley
	local cmd = (":vimgrep // %s | copen"):format(scope)
	vim.api.nvim_feedkeys(
		vim.api.nvim_replace_termcodes(cmd .. string.rep("<Left>", #scope + 10), true, false, true),
		"n",
		true
	)
end, { silent = true })
vim.keymap.set("n", "<leader>ff", function()
	local keys = vim.keycode(":find **<Tab><C-n><C-p>") -- workaround to go back to recursive search
	vim.fn.feedkeys(keys, "t")
end, { silent = true })
vim.keymap.set("n", "<leader>fb", function()
	local keys = vim.api.nvim_replace_termcodes(":b **<Tab>", true, false, true)
	vim.fn.feedkeys(keys, "t")
end, { silent = true })
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("n", "<esc>", "<cmd>nohlsearch<cr><esc>")
vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>")
vim.keymap.set("t", "<c-w>", "<c-\\><c-n><c-w>")
vim.keymap.set("n", "-", vim.cmd.Explore)
vim.keymap.set("n", "<c-x>", function()
	print("terminal")
end)

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("irohn/highlight-on-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- persistent colorscheme
local saved_colorscheme_file = vim.fn.stdpath("state") .. "/last_colorscheme"
if vim.fn.filereadable(saved_colorscheme_file) == 0 then
	vim.fn.writefile({ "default" }, saved_colorscheme_file)
end
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		vim.schedule(function()
			local saved_colorscheme = vim.fn.readfile(saved_colorscheme_file)[1] or "default"
			_G.saved_colorscheme = saved_colorscheme
			pcall(vim.cmd.colorscheme, saved_colorscheme)
		end)
	end,
})
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		pcall(vim.fn.writefile, { vim.g.colors_name or "default" }, saved_colorscheme_file)
	end,
})

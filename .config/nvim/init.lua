vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.o.cursorline = true
vim.o.clipboard = "unnamedplus"
vim.o.ignorecase = true
vim.o.number = true
vim.o.smartcase = true
vim.o.undofile = true
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.virtualedit = "block"
vim.o.wildmenu = true
vim.o.wildmode = "longest:full,full"
vim.opt.wildignore:append({ "./", "../" })
vim.opt.path:append({ "**" })

local ripgrep = require("irohn.ripgrep")
local fd = require("irohn.fd")

ripgrep.setup()
fd.setup()

local function feed_command(cmd, left)
	vim.api.nvim_feedkeys(
		vim.api.nvim_replace_termcodes(cmd .. string.rep("<Left>", left or 0), true, false, true),
		"n",
		true
	)
end

local function open_grep_prompt(scope)
	if scope == "" then
		scope = nil
	end

	if ripgrep.is_available then
		local suffix = scope and (" " .. vim.fn.fnameescape(scope)) or ""
		feed_command(":silent grep! " .. suffix, #suffix)
		return
	end

	local target = scope and vim.fn.fnameescape(scope) or "**"
	local cmd = (":vimgrep // %s | copen"):format(target)
	feed_command(cmd, #target + 10)
end

vim.keymap.set("n", "<leader>/", function()
	open_grep_prompt(vim.fn.expand("%"))
end, { silent = true })
vim.keymap.set("n", "<leader>fg", function()
	open_grep_prompt()
end, { silent = true })
local function open_find_files_prompt(path_prefix)
	local target = path_prefix and (vim.fn.fnameescape(path_prefix) .. "/") or ""
	local keys = vim.keycode(":FindFiles " .. target)
	vim.fn.feedkeys(keys, "t")
end
_G.open_find_files_prompt = open_find_files_prompt

local function find_files_complete(arglead)
	if not fd.is_available then
		return vim.fn.getcompletion(arglead, "file")
	end

	return fd.find(arglead ~= "" and arglead or "**")
end

vim.api.nvim_create_user_command("FindFiles", function(opts)
	local query = opts.args ~= "" and opts.args or "**"
	local matches = fd.is_available and fd.find(query) or vim.fn.glob(query, false, true)

	if #matches == 0 then
		vim.notify(("No files match %q"):format(query), vim.log.levels.WARN)
		return
	end

	if #matches == 1 then
		vim.cmd.edit(vim.fn.fnameescape(matches[1]))
		return
	end

	local items = vim.tbl_map(function(filename)
		return { filename = filename }
	end, matches)
	vim.fn.setqflist({}, " ", { title = ("FindFiles %s"):format(query), items = items })
	vim.cmd.copen()
end, {
	nargs = "*",
	complete = find_files_complete,
})

vim.keymap.set("n", "<leader>ff", function()
	open_find_files_prompt()
end, { silent = true })
vim.keymap.set("n", "<leader>fb", function()
	vim.fn.feedkeys(vim.keycode(":buffer <Tab>"), "t")
end, { silent = true })
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("n", "<esc>", "<cmd>nohlsearch<cr><esc>")
vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>")
vim.keymap.set("t", "<c-w>", "<c-\\><c-n><c-w>")
vim.keymap.set("n", "-", vim.cmd.Explore)

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

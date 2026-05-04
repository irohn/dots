-- credit: https://github.com/tpope/vim-vinegar
vim.g.netrw_banner = 0
vim.g.netrw_list_hide = ([[%s,%s]]):format(
	table.concat(
		vim.tbl_map(function(p)
			p = vim.fn.escape(p, [[.$~]])
			p = p:gsub("%*", ".*")
			return "^" .. p .. "/\\=$"
		end, vim.split(vim.o.wildignore, ",", { trimempty = true })),
		","
	),
	[[^\.\.\=/\=$]]
)
vim.g.netrw_sort_sequence = "[/]$,*,"
	.. table.concat(
		vim.tbl_map(function(s)
			return ([[\%%(%s\)[*@]\=$]]):format(vim.fn.escape(s, [[.*$~]]))
		end, vim.split(vim.o.suffixes, ",", { trimempty = true })),
		","
	)
local netrw_positions = {}
local netrw_fallbacks = {}

local function netrw_entry_name(line)
	return line:gsub("^([(| ]*)", ""):gsub("%s*[/*|@=]+%s*$", "")
end

local function netrw_find_entry_line(buf, name)
	for lnum, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
		if netrw_entry_name(line) == name then
			return lnum
		end
	end
end

local function netrw_restore_cursor(buf, dir)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	local win = vim.fn.bufwinid(buf)
	if win == -1 then
		return
	end
	if netrw_positions[dir] then
		pcall(vim.api.nvim_win_set_cursor, win, netrw_positions[dir])
		return
	end
	local fallback = netrw_fallbacks[dir]
	if fallback then
		local line = netrw_find_entry_line(buf, fallback)
		if line then
			pcall(vim.api.nvim_win_set_cursor, win, { line, 0 })
			netrw_fallbacks[dir] = nil
		end
	end
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "netrw",
	callback = function(ev)
		vim.schedule(function()
			local dir = vim.b[ev.buf].netrw_curdir
			if dir then
				netrw_restore_cursor(ev.buf, dir)
			end
		end)
		vim.api.nvim_create_autocmd("BufLeave", {
			buffer = ev.buf,
			callback = function()
				local dir = vim.b[ev.buf].netrw_curdir
				if dir then
					netrw_positions[dir] = vim.api.nvim_win_get_cursor(0)
				end
			end,
		})
		vim.keymap.set("n", "-", function()
			local dir = vim.b.netrw_curdir or vim.fn.expand("%:h")
			local parent = vim.fn.fnamemodify(dir, ":h")
			local fallback = vim.fn.fnamemodify(dir, ":t")
			netrw_fallbacks[parent] = fallback
			vim.cmd("edit " .. parent)
			vim.schedule(function()
				if vim.bo.filetype == "netrw" and vim.b.netrw_curdir == parent then
					netrw_restore_cursor(vim.api.nvim_get_current_buf(), parent)
				end
			end)
		end, { buffer = true, silent = true })
		vim.keymap.set("n", "~", ":edit ~/<CR>", { buffer = true, silent = true })
		vim.keymap.set("n", "<leader>ff", function()
			open_find_files_prompt(vim.b.netrw_curdir or vim.fn.getcwd())
		end, { buffer = true, silent = true })
		vim.keymap.set("n", ".", function()
			local name = netrw_entry_name(vim.fn.getline("."))
			local path = vim.fn.fnameescape((vim.b.netrw_curdir or ".") .. "/" .. name)
			vim.fn.feedkeys(":" .. path, "n")
		end, { buffer = true, silent = true })
		vim.keymap.set("n", "y.", function()
			local name = netrw_entry_name(vim.fn.getline("."))
			vim.fn.setreg(vim.v.register, vim.fn.fnamemodify((vim.b.netrw_curdir or ".") .. "/" .. name, ":p"))
		end, { buffer = true, silent = true })
	end,
})

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
vim.api.nvim_create_autocmd("FileType", {
	pattern = "netrw",
	callback = function(ev)
		vim.schedule(function()
			local dir = vim.b[ev.buf].netrw_curdir
			if dir and netrw_positions[dir] then
				pcall(vim.api.nvim_win_set_cursor, 0, netrw_positions[dir])
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
			vim.cmd("edit " .. vim.fn.fnamemodify(dir, ":h"))
		end, { buffer = true, silent = true })
		vim.keymap.set("n", "~", ":edit ~/<CR>", { buffer = true, silent = true })
		vim.keymap.set("n", ".", function()
			local name = vim.fn.getline("."):gsub([[^\(| %)*]], ""):gsub([[[/*|@=]\s*$]], "")
			local path = vim.fn.fnameescape((vim.b.netrw_curdir or ".") .. "/" .. name)
			vim.fn.feedkeys(":" .. path, "n")
		end, { buffer = true, silent = true })
		vim.keymap.set("n", "y.", function()
			local name = vim.fn.getline("."):gsub([[^\(| %)*]], ""):gsub([[[/*|@=]\s*$]], "")
			vim.fn.setreg(vim.v.register, vim.fn.fnamemodify((vim.b.netrw_curdir or ".") .. "/" .. name, ":p"))
		end, { buffer = true, silent = true })
	end,
})

local uv = vim.uv or vim.loop

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "git" })
end

local function split_lines(output)
	output = (output or ""):gsub("\r\n", "\n")
	if output:sub(-1) == "\n" then
		output = output:sub(1, -2)
	end
	if output == "" then
		return {}
	end
	return vim.split(output, "\n", { plain = true })
end

local function current_git_dir()
	local name = vim.api.nvim_buf_get_name(0)
	if vim.bo.buftype == "" and name ~= "" then
		return vim.fn.fnamemodify(name, ":p:h")
	end
	return vim.fn.getcwd()
end

local function git_root(dir)
	local result = vim.system({ "git", "-C", dir, "rev-parse", "--show-toplevel" }, { text = true }):wait()
	if result.code ~= 0 then
		notify("Not inside a git repository", vim.log.levels.WARN)
		return nil
	end
	return vim.trim(result.stdout or "")
end

local function run_git(root, args)
	local command = { "git", "-C", root }
	vim.list_extend(command, args)

	local result = vim.system(command, { text = true }):wait()
	if result.code ~= 0 then
		local message = vim.trim((result.stderr or "") .. "\n" .. (result.stdout or ""))
		notify(message ~= "" and message or "Git command failed", vim.log.levels.ERROR)
		return nil
	end

	return result.stdout or ""
end

local function is_tracked(root, path)
	local result = vim.system({ "git", "-C", root, "ls-files", "--error-unmatch", "--", path }, { text = true }):wait()
	return result.code == 0
end

local function relative_path(root, path)
	root = vim.fs.normalize(root):gsub("/$", "")
	path = vim.fs.normalize(path)

	local prefix = root .. "/"
	if path:sub(1, #prefix) ~= prefix then
		return nil
	end

	return path:sub(#prefix + 1)
end

local function absolute_path(root, path)
	if path:sub(1, 1) == "/" then
		return path
	end
	return root .. "/" .. path
end

local function parse_file_reference(line, root)
	local path, lnum, col = line:match("^%s*([^:]+):(%d+):(%d+)")
	if not path then
		path, lnum = line:match("^%s*([^:]+):(%d+)")
	end
	if not path or not root then
		return nil
	end

	local file = absolute_path(root, path)
	if not uv.fs_stat(file) then
		return nil
	end

	return { path = path, line = tonumber(lnum), col = tonumber(col) }
end

local function open_entry(root, entry, source_tab, close_current_tab)
	if not entry or not entry.path then
		return
	end

	local target = absolute_path(entry.root or root, entry.path)
	if not uv.fs_stat(target) then
		notify(("File %s was not found."):format(entry.path), vim.log.levels.WARN)
		return
	end

	if close_current_tab then
		local current_tab = vim.api.nvim_get_current_tabpage()
		if #vim.api.nvim_list_tabpages() > 1 then
			pcall(vim.cmd.tabclose)
		end
		if vim.api.nvim_tabpage_is_valid(source_tab) then
			vim.api.nvim_set_current_tabpage(source_tab)
		elseif vim.api.nvim_tabpage_is_valid(current_tab) then
			vim.api.nvim_set_current_tabpage(current_tab)
		end
	end

	vim.cmd.edit(vim.fn.fnameescape(target))

	local line = tonumber(entry.line)
	if line and line > 0 then
		local last = vim.api.nvim_buf_line_count(0)
		local col = math.max((tonumber(entry.col) or 1) - 1, 0)
		pcall(vim.api.nvim_win_set_cursor, 0, { math.min(line, last), col })
	end
end

local function close_output()
	local has_other_tabs = #vim.api.nvim_list_tabpages() > 1
	local only_window_in_tab = #vim.api.nvim_tabpage_list_wins(0) == 1
	if has_other_tabs and only_window_in_tab then
		vim.cmd.tabclose()
		return
	end

	local ok = pcall(vim.cmd.close)
	if not ok then
		vim.cmd.bdelete()
	end
end

local function open_output(title, lines, entries, root, opts)
	if not lines or #lines == 0 then
		return false
	end

	opts = opts or {}
	entries = entries or {}
	local source_tab = vim.api.nvim_get_current_tabpage()
	vim.cmd.tabnew()

	local buf = vim.api.nvim_get_current_buf()
	pcall(vim.api.nvim_buf_set_name, buf, ("git://%s/%d"):format(title:gsub("%s+", "-"), uv.hrtime()))
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].buflisted = false
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = "git"

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].readonly = true

	vim.keymap.set("n", "q", close_output, { buffer = buf, nowait = true, silent = true })
	vim.keymap.set("n", "<CR>", function()
		local row = vim.api.nvim_win_get_cursor(0)[1]
		local entry = entries[row] or parse_file_reference(vim.api.nvim_get_current_line(), root)
		open_entry(root, entry, source_tab, opts.close_tab_on_open)
	end, { buffer = buf, silent = true })

	return true
end

local function parse_status(output)
	local parts = vim.split(output, "\0", { plain = true, trimempty = true })
	local lines = {}
	local entries = {}
	local i = 1

	while i <= #parts do
		local record = parts[i]
		local status = record:sub(1, 2)
		local path = record:sub(4)
		local line

		if status:find("[RC]") and parts[i + 1] then
			local old_path = parts[i + 1]
			line = status .. " " .. old_path .. " -> " .. path
			i = i + 2
		else
			line = status .. " " .. path
			i = i + 1
		end

		lines[#lines + 1] = line
		entries[#lines] = { path = path }
	end

	return lines, entries
end

local function set_status_quickfix(root, lines, entries)
	local items = {}
	for i, line in ipairs(lines) do
		local entry = entries[i]
		if entry and entry.path then
			items[#items + 1] = {
				filename = absolute_path(root, entry.path),
				lnum = 1,
				text = line,
			}
		end
	end

	vim.fn.setqflist({}, " ", { title = "git status", items = items })
end

local function parse_log_output(output, default_path)
	local lines = split_lines(output)
	local entries = {}
	local current_path = default_path

	for i, line in ipairs(lines) do
		local old_path = line:match("^%-%-%- a/(.+)$")
		local new_path = line:match("^%+%+%+ b/(.+)$")
		local hunk_line = line:match("^@@ %-%d+,?%d* %+(%d+)")

		if new_path and new_path ~= "/dev/null" then
			current_path = new_path
			entries[i] = { path = new_path }
		elseif old_path and old_path ~= "/dev/null" then
			entries[i] = { path = old_path }
		elseif hunk_line then
			entries[i] = { path = current_path, line = tonumber(hunk_line) }
		end
	end

	return lines, entries
end

local function open_current_line_log(first_line, last_line)
	local file = vim.api.nvim_buf_get_name(0)
	if vim.bo.buftype ~= "" or file == "" then
		notify("Current buffer is not a file", vim.log.levels.WARN)
		return
	end

	local root = git_root(vim.fn.fnamemodify(file, ":p:h"))
	if not root then
		return
	end

	local path = relative_path(root, vim.fn.fnamemodify(file, ":p"))
	if not path then
		notify("Current file is outside the git repository", vim.log.levels.ERROR)
		return
	end
	if not is_tracked(root, path) then
		notify("Current file is not tracked by git", vim.log.levels.WARN)
		return
	end

	local output = run_git(root, { "--no-pager", "log", "-L", ("%d,%d:%s"):format(first_line, last_line, path) })
	if not output then
		return
	end

	local lines, entries = parse_log_output(output, path)
	if #lines == 0 then
		notify("No git log output")
		return
	end

	open_output(("git log -L %d,%d"):format(first_line, last_line), lines, entries, root)
end

vim.keymap.set("n", "<leader>gs", function()
	local root = git_root(current_git_dir())
	if not root then
		return
	end

	local output = run_git(root, { "status", "--porcelain=v1", "-z", "--untracked-files=all" })
	if not output then
		return
	end

	local lines, entries = parse_status(output)
	if #lines == 0 then
		notify("Git status is clean")
		return
	end

	set_status_quickfix(root, lines, entries)
	open_output("git status", lines, entries, root, { close_tab_on_open = true })
end, { desc = "git status" })

vim.keymap.set("n", "<leader>gL", function()
	local root = git_root(current_git_dir())
	if not root then
		return
	end

	local output = run_git(root, { "--no-pager", "log", "--oneline" })
	if not output then
		return
	end

	local lines = split_lines(output)
	if #lines == 0 then
		notify("No git log output")
		return
	end

	open_output("git log", lines, nil, root)
end, { desc = "git log" })

vim.keymap.set("n", "<leader>gl", function()
	local line = vim.api.nvim_win_get_cursor(0)[1]
	open_current_line_log(line, line)
end, { desc = "git log line" })

vim.keymap.set("v", "<leader>gl", function()
	local first_line = vim.fn.line("v")
	local last_line = vim.fn.line(".")
	if first_line > last_line then
		first_line, last_line = last_line, first_line
	end

	open_current_line_log(first_line, last_line)
end, { desc = "git log line" })

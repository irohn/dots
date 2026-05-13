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

local function run_git(root, args, allowed_codes)
	local command = { "git", "-C", root }
	vim.list_extend(command, args)

	allowed_codes = allowed_codes or { 0 }
	local result = vim.system(command, { text = true }):wait()
	if not vim.tbl_contains(allowed_codes, result.code) then
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
	local buf = vim.api.nvim_get_current_buf()
	local has_other_tabs = #vim.api.nvim_list_tabpages() > 1
	local only_window_in_tab = #vim.api.nvim_tabpage_list_wins(0) == 1
	if has_other_tabs and only_window_in_tab then
		vim.cmd.tabclose()
		if vim.api.nvim_buf_is_valid(buf) then
			pcall(vim.api.nvim_buf_delete, buf, { force = true })
		end
		return
	end

	local ok = pcall(vim.cmd.close)
	if not ok and vim.api.nvim_buf_is_valid(buf) then
		pcall(vim.api.nvim_buf_delete, buf, { force = true })
	elseif vim.api.nvim_buf_is_valid(buf) then
		pcall(vim.api.nvim_buf_delete, buf, { force = true })
	end
end

local function go_back_or_close(buf, prev_buf)
	if prev_buf and vim.api.nvim_buf_is_valid(prev_buf) then
		vim.api.nvim_set_current_buf(prev_buf)
		if vim.api.nvim_buf_is_valid(buf) then
			pcall(vim.api.nvim_buf_delete, buf, { force = true })
		end
		return
	end
	close_output()
end

local function open_output(title, lines, entries, root, opts)
	if not lines or #lines == 0 then
		return false
	end

	opts = opts or {}
	entries = entries or {}
	local source_tab = vim.api.nvim_get_current_tabpage()
	local prev_buf = opts.back_buf or (opts.reuse_current_tab and vim.api.nvim_get_current_buf() or nil)
	if opts.reuse_current_tab then
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_set_current_buf(buf)
	else
		vim.cmd.tabnew()
	end

	local buf = vim.api.nvim_get_current_buf()
	pcall(vim.api.nvim_buf_set_name, buf, ("git://%s/%d"):format(title:gsub("%s+", "-"), uv.hrtime()))
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "hide"
	vim.bo[buf].buflisted = false
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = "git"
	vim.b[buf].git_back_buf = prev_buf

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].readonly = true

	vim.keymap.set("n", "q", function()
		go_back_or_close(buf, prev_buf)
	end, { buffer = buf, nowait = true, silent = true })
	vim.keymap.set("n", "<Esc>", function()
		go_back_or_close(buf, prev_buf)
	end, { buffer = buf, nowait = true, silent = true })
	vim.keymap.set("n", "<CR>", function()
		local row = vim.api.nvim_win_get_cursor(0)[1]
		local line = vim.api.nvim_get_current_line()
		local entry = entries[row] or parse_file_reference(line, root)
		if opts.on_enter then
			return opts.on_enter(entry, line, source_tab)
		end
		open_entry(root, entry, source_tab, opts.close_tab_on_open)
	end, { buffer = buf, silent = true })
	if opts.on_diff then
		vim.keymap.set("n", "gd", function()
			local row = vim.api.nvim_win_get_cursor(0)[1]
			opts.on_diff(entries[row], vim.api.nvim_get_current_line())
		end, { buffer = buf, silent = true })
	end

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
			lines[#lines + 1] = line
			entries[#lines] = { path = path, old_path = old_path, status = status }
		else
			line = status .. " " .. path
			i = i + 1
			lines[#lines + 1] = line
			entries[#lines] = { path = path, status = status }
		end
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

local function parse_show_stat_output(output)
	local lines, entries = parse_log_output(output)

	for i, line in ipairs(lines) do
		if not entries[i] then
			local path = vim.trim((line:match("^%s*(.-)%s+|%s+%d+") or ""))
			if path ~= "" and not path:match("^%d+ files? changed") then
				entries[i] = { path = path }
			end
		end
	end

	return lines, entries
end

local function open_commit_file_diff(root, commit, path, back_buf)
	local output = run_git(root, { "--no-pager", "show", commit, "--", path })
	if not output then
		return
	end

	local lines, entries = parse_log_output(output, path)
	if #lines == 0 then
		notify("No git diff output")
		return
	end

	open_output(("git show %s -- %s"):format(commit, path), lines, entries, root, {
		reuse_current_tab = true,
		back_buf = back_buf,
	})
end

local function open_commit_show(root, commit)
	local output = run_git(root, { "--no-pager", "show", "--stat", commit })
	if not output then
		return
	end

	local lines, entries = parse_show_stat_output(output)
	if #lines == 0 then
		notify("No git show output")
		return
	end

	open_output(("git show %s"):format(commit), lines, entries, root, {
		reuse_current_tab = true,
		on_enter = function(entry, line, source_tab)
			if entry and entry.path then
				return open_commit_file_diff(
					root,
					commit,
					entry.path,
					vim.b.git_back_buf or vim.api.nvim_get_current_buf()
				)
			end
			open_entry(root, parse_file_reference(line, root), source_tab)
		end,
	})
end

local function open_status_file_diff(root, entry)
	if not entry or not entry.path then
		return
	end

	local output
	if entry.status == "??" then
		local target = absolute_path(root, entry.path)
		if not uv.fs_stat(target) then
			notify(("File %s was not found."):format(entry.path), vim.log.levels.WARN)
			return
		end
		output = run_git(root, { "--no-pager", "diff", "--no-index", "--", "/dev/null", target }, { 0, 1 })
	else
		output = run_git(root, { "--no-pager", "diff", "HEAD", "--", entry.path })
	end
	if not output then
		return
	end

	local lines, entries = parse_log_output(output, entry.path)
	if #lines == 0 then
		notify("No git diff output")
		return
	end

	open_output(("git diff %s"):format(entry.path), lines, entries, root)
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
	open_output("git status", lines, entries, root, {
		close_tab_on_open = true,
		on_diff = function(entry)
			open_status_file_diff(root, entry)
		end,
	})
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

	local entries = {}
	for i, line in ipairs(lines) do
		local commit = line:match("^(%x+)")
		if commit then
			entries[i] = { commit = commit }
		end
	end

	open_output("git log", lines, entries, root, {
		on_enter = function(entry)
			if entry and entry.commit then
				open_commit_show(root, entry.commit)
			end
		end,
	})
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

local M = {}

M.is_available = vim.fn.executable("fd") == 1

local function notify_error(result)
	local message = (result.stderr or ""):gsub("%s+$", "")
	if message == "" then
		message = ("fd exited with code %d"):format(result.code)
	end
	vim.schedule(function()
		vim.notify(message, vim.log.levels.ERROR, { title = "fd" })
	end)
end

function M.find(cmdarg, _)
	local search_root, pattern = ".", cmdarg

	-- `**` is Vim's recursive-glob marker (used by :find with the native
	-- file searcher). fd recurses by default, so the markers are noise that
	-- would otherwise reach fd's regex parser and error out.
	if pattern == "**" then
		pattern = ""
	elseif pattern:sub(-3) == "/**" then
		search_root = pattern:sub(1, -4)
		pattern = ""
	else
		local slash = pattern:match("^.*()/")
		if slash then
			search_root = pattern:sub(1, slash - 1)
			pattern = pattern:sub(slash + 1)
		end
	end

	pattern = pattern:gsub("%*%*", "")

	if search_root == "" then
		search_root = "."
	end

	local command = { "fd", "--type", "f", "--hidden", "--full-path", "--exclude", ".git" }
	if pattern ~= "" then
		table.insert(command, pattern)
	end

	local result = vim.system(command, { cwd = search_root, text = true }):wait()
	if result.code ~= 0 then
		notify_error(result)
		return {}
	end

	local matches = vim.split(result.stdout or "", "\n", { trimempty = true })
	if search_root == "." then
		return matches
	end

	return vim.tbl_map(function(match)
		return search_root .. "/" .. match
	end, matches)
end

function M.setup()
	if not M.is_available then
		return false
	end

	_G.open_find_files_fd = M.find
	vim.o.findfunc = "v:lua.open_find_files_fd"
	return true
end

return M

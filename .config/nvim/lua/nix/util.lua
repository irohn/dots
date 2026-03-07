local uv = vim.uv or vim.loop

local M = {}

local cache = {}
local inflight = {}

function M.join(...)
	return table.concat({ ... }, "/")
end

function M.exists(path)
	return uv.fs_stat(path) ~= nil
end

local function key_id(key)
	return vim.fn.sha256(key):sub(1, 16)
end

local function ensure_cache_dir(parts)
	local dir = M.join(vim.fn.stdpath("data"), "nix", unpack(parts))
	vim.fn.mkdir(dir, "p")
	return dir
end

local function cache_file(dir, key)
	return M.join(dir, key_id(key) .. ".path")
end

local function read_cached_path(path)
	if not M.exists(path) then
		return nil
	end
	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok or type(lines) ~= "table" or lines[1] == nil then
		return nil
	end
	local resolved_path = vim.trim(lines[1])
	if resolved_path ~= "" and M.exists(resolved_path) then
		return resolved_path
	end
	return nil
end

local function write_cached_path(path, resolved_path)
	pcall(vim.fn.writefile, { resolved_path }, path)
end

function M.set_default_nixpkgs(target, nixpkgs)
	if type(nixpkgs) == "string" and nixpkgs ~= "" then
		target.default_nixpkgs = nixpkgs
	end
end

function M.resolve_nixpkgs(explicit, default_nixpkgs)
	return explicit or default_nixpkgs or "nixpkgs"
end

local function cache_state(opts)
	if not opts.cache_key or not opts.cache_dir then
		return nil
	end
	local dir = ensure_cache_dir(opts.cache_dir)
	local path = cache_file(dir, opts.cache_key)
	return {
		key = opts.cache_key,
		path = path,
	}
end

local function resolve_cached(opts)
	local state = cache_state(opts)
	if not state then
		return nil, nil
	end
	if cache[state.key] and M.exists(cache[state.key]) then
		return cache[state.key], state
	end
	local cached_path = read_cached_path(state.path)
	if cached_path then
		cache[state.key] = cached_path
		return cached_path, state
	end
	return nil, state
end

local function notify_build_error(opts, message, detail)
	local prefix = opts.error_prefix or "nix.nvim"
	local suffix = detail and detail ~= "" and ("\n" .. detail) or ""
	vim.notify(("%s: %s%s"):format(prefix, message, suffix), vim.log.levels.ERROR)
end

local function finalize_build(opts, proc, state)
	if proc.code ~= 0 then
		notify_build_error(opts, ("failed to build %s"):format(opts.target), proc.stderr or "")
		return nil
	end

	local out_path = vim.trim(proc.stdout or "")
	if out_path == "" then
		notify_build_error(opts, ("empty build output for %s"):format(opts.target))
		return nil
	end

	if not opts.bin then
		return out_path
	end

	local resolved_path = M.join(out_path, "bin", opts.bin)
	if not M.exists(resolved_path) then
		notify_build_error(opts, ("binary '%s' not found in %s"):format(opts.bin, out_path))
		return nil
	end

	if state then
		cache[state.key] = resolved_path
		write_cached_path(state.path, resolved_path)
	end

	return resolved_path
end

function M.build(opts)
	local cached_path, state = resolve_cached(opts)
	if cached_path then
		return cached_path
	end

	local proc = vim.system({ "nix", "build", "--no-link", "--print-out-paths", opts.target }, { text = true }):wait()
	return finalize_build(opts, proc, state)
end

function M.build_async(opts, cb)
	local cached_path, state = resolve_cached(opts)
	if cached_path then
		cb(cached_path)
		return
	end

	if state and inflight[state.key] then
		table.insert(inflight[state.key], cb)
		return
	end
	if state then
		inflight[state.key] = { cb }
	end

	vim.system({ "nix", "build", "--no-link", "--print-out-paths", opts.target }, { text = true }, function(proc)
		vim.schedule(function()
			local resolved_path = finalize_build(opts, proc, state)
			if not state then
				cb(resolved_path)
				return
			end

			local callbacks = inflight[state.key] or {}
			inflight[state.key] = nil
			for _, callback in ipairs(callbacks) do
				pcall(callback, resolved_path)
			end
		end)
	end)
end

return M

local uv = vim.uv or vim.loop

local M = {
	default_nixpkgs = nil,
}

local cache = {}

local function join(...)
	return table.concat({ ... }, "/")
end

local function exists(path)
	return uv.fs_stat(path) ~= nil
end

local function key_id(key)
	return vim.fn.sha256(key):sub(1, 16)
end

local function cache_file(dir, key)
	return join(dir, key_id(key) .. ".path")
end

local function read_cached_path(path)
	if not exists(path) then
		return nil
	end
	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok or type(lines) ~= "table" or lines[1] == nil then
		return nil
	end
	local cmd_path = vim.trim(lines[1])
	if cmd_path ~= "" and exists(cmd_path) then
		return cmd_path
	end
	return nil
end

local function write_cached_path(path, cmd_path)
	pcall(vim.fn.writefile, { cmd_path }, path)
end

local function ensure_dir()
	local dir = join(vim.fn.stdpath("data"), "nix", "adapters", "conform")
	vim.fn.mkdir(dir, "p")
	return dir
end

function M.set_default_nixpkgs(nixpkgs)
	if type(nixpkgs) == "string" and nixpkgs ~= "" then
		M.default_nixpkgs = nixpkgs
	end
end

function M.cmd(attr, bin, opts)
	opts = opts or {}
	if type(attr) ~= "string" or attr == "" then
		error("nix.adapters.conform.cmd: attr must be a non-empty string")
	end
	if type(bin) ~= "string" or bin == "" then
		error("nix.adapters.conform.cmd: bin must be a non-empty string")
	end

	local nixpkgs = opts.nixpkgs or M.default_nixpkgs or "nixpkgs"
	local key = nixpkgs .. "#" .. attr .. "::" .. bin
	if cache[key] and exists(cache[key]) then
		return cache[key]
	end

	local adapter_dir = ensure_dir()
	local path_file = cache_file(adapter_dir, key)
	local cached_path = read_cached_path(path_file)
	if cached_path then
		cache[key] = cached_path
		return cached_path
	end

	local target = nixpkgs .. "#" .. attr
	local proc = vim.system({ "nix", "build", "--no-link", "--print-out-paths", target }, { text = true }):wait()
	if proc.code ~= 0 then
		vim.notify(("nix.nvim conform: failed to build %s\n%s"):format(target, proc.stderr or ""), vim.log.levels.ERROR)
		return bin
	end

	local out_path = vim.trim(proc.stdout or "")
	if out_path == "" then
		vim.notify(("nix.nvim conform: empty build output for %s"):format(target), vim.log.levels.ERROR)
		return bin
	end

	local direct_cmd = join(out_path, "bin", bin)
	if exists(direct_cmd) then
		cache[key] = direct_cmd
		write_cached_path(path_file, direct_cmd)
		return direct_cmd
	end

	vim.notify(("nix.nvim conform: binary '%s' not found in %s"):format(bin, out_path), vim.log.levels.ERROR)
	return bin
end

return M

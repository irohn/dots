local uv = vim.uv or vim.loop

local M = {
	default_nixpkgs = nil,
}

local nix_api = nil
local cache = {}
local inflight = {}

local function join(...)
	return table.concat({ ... }, "/")
end

local function exists(path)
	return uv.fs_stat(path) ~= nil
end

local function key_id(key)
	return vim.fn.sha256(key):sub(1, 16)
end

local function ensure_dir()
	local dir = join(vim.fn.stdpath("data"), "nix", "adapters", "lsp")
	vim.fn.mkdir(dir, "p")
	return dir
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

local function resolve_server(spec, opts)
	return {
		name = spec.name,
		attr = spec.attr or spec.name,
		bin = spec.bin or spec.attr or spec.name,
		args = spec.args or {},
		nixpkgs = spec.nixpkgs or opts.nixpkgs or M.default_nixpkgs or "nixpkgs",
	}
end

local function install_cmd_async(server, cb)
	local key = server.nixpkgs .. "#" .. server.attr .. "::" .. server.bin
	if cache[key] and exists(cache[key]) then
		cb(cache[key])
		return
	end

	local dir = ensure_dir()
	local path_file = cache_file(dir, key)
	local cached_path = read_cached_path(path_file)
	if cached_path then
		cache[key] = cached_path
		cb(cached_path)
		return
	end

	if inflight[key] then
		table.insert(inflight[key], cb)
		return
	end
	inflight[key] = { cb }

	local target = server.nixpkgs .. "#" .. server.attr
	vim.system({ "nix", "build", "--no-link", "--print-out-paths", target }, { text = true }, function(proc)
		vim.schedule(function()
			local resolved = nil
			if proc.code ~= 0 then
				vim.notify(
					("nix.nvim lsp: failed to build %s\n%s"):format(target, proc.stderr or ""),
					vim.log.levels.ERROR
				)
			else
				local out_path = vim.trim(proc.stdout or "")
				if out_path == "" then
					vim.notify(("nix.nvim lsp: empty build output for %s"):format(target), vim.log.levels.ERROR)
				else
					local cmd_path = join(out_path, "bin", server.bin)
					if not exists(cmd_path) then
						vim.notify(
							("nix.nvim lsp: binary '%s' not found in %s"):format(server.bin, out_path),
							vim.log.levels.ERROR
						)
					else
						cache[key] = cmd_path
						write_cached_path(path_file, cmd_path)
						resolved = cmd_path
					end
				end
			end

			local callbacks = inflight[key] or {}
			inflight[key] = nil
			for _, callback in ipairs(callbacks) do
				pcall(callback, resolved)
			end
		end)
	end)
end

local function normalize_servers(servers)
	local out = {}
	servers = servers or {}

	if not vim.islist(servers) then
		for name, value in pairs(servers) do
			if type(name) == "string" and name ~= "" then
				if type(value) == "string" and value ~= "" then
					table.insert(out, { name = name, attr = value, bin = value, args = {} })
				elseif type(value) == "table" then
					local spec = vim.deepcopy(value)
					spec.name = spec.name or name
					spec.attr = spec.attr or spec[1] or spec.name
					spec.bin = spec.bin or spec.attr
					spec.args = spec.args or {}
					spec[1] = nil
					table.insert(out, spec)
				end
			end
		end
		return out
	end

	for _, server in ipairs(servers) do
		if type(server) == "string" then
			table.insert(out, { name = server, attr = server, bin = server, args = {} })
		elseif type(server) == "table" then
			local spec = vim.deepcopy(server)
			spec.name = spec.name or spec[1]
			spec.attr = spec.attr or spec.name
			spec.bin = spec.bin or spec.attr
			spec.args = spec.args or {}
			spec[1] = nil
			if type(spec.name) == "string" and spec.name ~= "" then
				table.insert(out, spec)
			end
		end
	end
	return out
end

local function apply_server_async(server)
	install_cmd_async(server, function(cmd_path)
		if not cmd_path then
			return
		end

		local cmd = { cmd_path }
		for _, arg in ipairs(server.args or {}) do
			table.insert(cmd, arg)
		end

		vim.lsp.config(server.name, { cmd = cmd })
		vim.lsp.enable(server.name)
	end)
end

function M.set_nix_api(api)
	nix_api = api
end

function M.set_default_nixpkgs(nixpkgs)
	if type(nixpkgs) == "string" and nixpkgs ~= "" then
		M.default_nixpkgs = nixpkgs
	end
end

function M.enable(servers, opts)
	opts = opts or {}
	local normalized = normalize_servers(servers)
	if #normalized == 0 then
		return
	end

	local resolved = {}
	for _, spec in ipairs(normalized) do
		table.insert(resolved, resolve_server(spec, opts))
	end

	local function run()
		for _, server in ipairs(resolved) do
			apply_server_async(server)
		end
	end

	if nix_api and nix_api.has_spec and nix_api.has_spec("nvim-lspconfig") then
		if nix_api.is_loaded and nix_api.is_loaded("nvim-lspconfig") then
			run()
		else
			nix_api.on_plugin_loaded("nvim-lspconfig", run)
		end
		return
	end

	run()
end

return M

local util = require("nix.util")

local M = {
	default_nixpkgs = nil,
}

local nix_api = nil

local function resolve_server(spec, opts)
	return {
		name = spec.name,
		attr = spec.attr or spec.name,
		bin = spec.bin or spec.attr or spec.name,
		args = spec.args or {},
		nixpkgs = util.resolve_nixpkgs(spec.nixpkgs or opts.nixpkgs, M.default_nixpkgs),
	}
end

local function install_cmd_async(server, cb)
	local key = server.nixpkgs .. "#" .. server.attr .. "::" .. server.bin
	local target = server.nixpkgs .. "#" .. server.attr
	util.build_async({
		target = target,
		bin = server.bin,
		cache_dir = { "adapters", "lsp" },
		cache_key = key,
		error_prefix = "nix.nvim lsp",
	}, cb)
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
	util.set_default_nixpkgs(M, nixpkgs)
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

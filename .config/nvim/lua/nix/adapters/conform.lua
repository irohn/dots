local util = require("nix.util")

local M = {
	default_nixpkgs = nil,
}

function M.set_default_nixpkgs(nixpkgs)
	util.set_default_nixpkgs(M, nixpkgs)
end

function M.cmd(attr, bin, opts)
	opts = opts or {}
	if type(attr) ~= "string" or attr == "" then
		error("nix.adapters.conform.cmd: attr must be a non-empty string")
	end
	if type(bin) ~= "string" or bin == "" then
		error("nix.adapters.conform.cmd: bin must be a non-empty string")
	end

	local nixpkgs = util.resolve_nixpkgs(opts.nixpkgs, M.default_nixpkgs)
	local key = nixpkgs .. "#" .. attr .. "::" .. bin

	local target = nixpkgs .. "#" .. attr
	return util.build({
		target = target,
		bin = bin,
		cache_dir = { "adapters", "conform" },
		cache_key = key,
		error_prefix = "nix.nvim conform",
	}) or bin
end

return M

local uv = vim.uv or vim.loop

local M = {}
local util = require("nix.util")

local state = {
	specs = {},
	order = {},
	loaded = {},
	loading = {},
	loading_async = {},
	installed = {},
	installing = {},
	commands_ready = false,
	on_loaded = {},
	emitted_loaded = {},
}

local join = util.join

local function listify(value)
	if value == nil then
		return {}
	end
	if type(value) == "table" and not vim.islist(value) then
		return { value }
	end
	if type(value) ~= "table" then
		return { value }
	end
	return value
end

local function module_to_path(module)
	return module:gsub("%.", "/")
end

local function file_to_module(file_path)
	local rel = file_path:match("/lua/(.+)%.lua$")
	if not rel then
		return nil
	end
	rel = rel:gsub("/init$", "")
	return rel:gsub("/", ".")
end

local function collect_import_specs(imports)
	local specs = {}
	for _, import in ipairs(listify(imports)) do
		if type(import) ~= "string" or import == "" then
			error("nix.nvim: import must be a non-empty module path string")
		end

		local files = vim.api.nvim_get_runtime_file(join("lua", module_to_path(import), "**", "*.lua"), true)
		if #files == 0 then
			vim.notify(("nix.nvim: import directory not found or empty: %s"):format(import), vim.log.levels.WARN)
		end

		table.sort(files)
		for _, file in ipairs(files) do
			local module = file_to_module(file)
			if module then
				local ok, spec_or_err = pcall(require, module)
				if not ok then
					error(("nix.nvim: failed to import plugin spec from %s\n%s"):format(module, spec_or_err))
				end

				if type(spec_or_err) ~= "table" then
					error(("nix.nvim: imported module %s must return a table"):format(module))
				end

				if vim.islist(spec_or_err) and type(spec_or_err[1]) == "table" then
					for _, spec in ipairs(spec_or_err) do
						table.insert(specs, spec)
					end
				else
					table.insert(specs, spec_or_err)
				end
			end
		end
	end

	return specs
end

local exists = util.exists

local function has_runtime_layout(path)
	for _, name in ipairs({ "plugin", "lua", "autoload", "ftdetect", "syntax", "colors", "doc" }) do
		if exists(join(path, name)) then
			return true
		end
	end
	return false
end

local function resolve_plugin_root(out_path, plugin_name)
	if has_runtime_layout(out_path) then
		return out_path
	end

	local exact = join(out_path, "share", "vim-plugins", plugin_name)
	if exists(exact) then
		return exact
	end

	local candidates = vim.fn.glob(join(out_path, "share", "vim-plugins", "*"), false, true)
	for _, candidate in ipairs(candidates) do
		if has_runtime_layout(candidate) then
			return candidate
		end
	end

	return nil
end

local function ensure_pack_dir()
	local opt_dir = join(vim.fn.stdpath("data"), "site", "pack", "nix", "opt")
	vim.fn.mkdir(opt_dir, "p")
	return opt_dir
end

local function plugin_link_path(name)
	return join(ensure_pack_dir(), name)
end

local function github_repo_name(repo)
	return (repo:gsub("%.git$", ""):match("/([^/]+)$") or repo)
end

local function clone_dir_name(spec)
	if type(spec.repo) == "string" and spec.repo ~= "" then
		return spec.repo:gsub("%.git$", ""):gsub("[/\\:]", "__")
	end
	return spec.name
end

local function existing_link(spec)
	local link_path = plugin_link_path(spec.name)
	if exists(link_path) then
		return link_path
	end
	return nil
end

local function build_plugin(spec)
	if type(spec.dir) == "string" and spec.dir ~= "" then
		if not exists(spec.dir) then
			vim.notify(("nix.nvim: local plugin directory not found for %s: %s"):format(spec.name, spec.dir), vim.log.levels.ERROR)
			return nil
		end

		local root = resolve_plugin_root(spec.dir, spec.name) or spec.dir
		local opt_dir = ensure_pack_dir()
		local link_path = join(opt_dir, spec.name)
		if exists(link_path) then
			vim.fn.delete(link_path, "rf")
		end

		local ok, err = uv.fs_symlink(root, link_path)
		if not ok then
			vim.notify(
				("nix.nvim: failed to link %s -> %s (%s)"):format(link_path, root, err or "unknown"),
				vim.log.levels.ERROR
			)
			return nil
		end

		return link_path
	end

	if type(spec.url) == "string" and spec.url ~= "" then
		local clone_dir = join(vim.fn.stdpath("data"), "nix", "repos", clone_dir_name(spec))
		if not exists(clone_dir) then
			vim.fn.mkdir(vim.fn.fnamemodify(clone_dir, ":h"), "p")
			local clone = vim.system({ "git", "clone", "--filter=blob:none", spec.url, clone_dir }, { text = true }):wait()
			if clone.code ~= 0 then
				vim.notify(("nix.nvim: failed to clone %s\n%s"):format(spec.url, clone.stderr or ""), vim.log.levels.ERROR)
				return nil
			end
		else
			local pull = vim.system({ "git", "-C", clone_dir, "pull", "--ff-only" }, { text = true }):wait()
			if pull.code ~= 0 then
				vim.notify(("nix.nvim: failed to update %s\n%s"):format(spec.url, pull.stderr or ""), vim.log.levels.ERROR)
				return nil
			end
		end

		local root = resolve_plugin_root(clone_dir, spec.name) or clone_dir
		local opt_dir = ensure_pack_dir()
		local link_path = join(opt_dir, spec.name)
		if exists(link_path) then
			vim.fn.delete(link_path, "rf")
		end

		local ok, err = uv.fs_symlink(root, link_path)
		if not ok then
			vim.notify(
				("nix.nvim: failed to link %s -> %s (%s)"):format(link_path, root, err or "unknown"),
				vim.log.levels.ERROR
			)
			return nil
		end

		return link_path
	end

	local target = (spec.nixpkgs or "nixpkgs") .. "#vimPlugins." .. spec.name
	local out_path = util.build({
		target = target,
		error_prefix = "nix.nvim",
	})
	if not out_path then
		return nil
	end

	local root = resolve_plugin_root(out_path, spec.name)
	if not root then
		vim.notify(
			("nix.nvim: could not locate runtime directory for %s in %s"):format(spec.name, out_path),
			vim.log.levels.ERROR
		)
		return nil
	end

	local opt_dir = ensure_pack_dir()
	local link_path = join(opt_dir, spec.name)
	if exists(link_path) then
		vim.fn.delete(link_path, "rf")
	end

	local ok, err = uv.fs_symlink(root, link_path)
	if not ok then
		vim.notify(
			("nix.nvim: failed to link %s -> %s (%s)"):format(link_path, root, err or "unknown"),
			vim.log.levels.ERROR
		)
		return nil
	end

	return link_path
end

local function build_plugin_async(spec, cb)
	if type(spec.dir) == "string" and spec.dir ~= "" then
		vim.schedule(function()
			cb(build_plugin(spec))
		end)
		return
	end

	if type(spec.url) == "string" and spec.url ~= "" then
		local clone_dir = join(vim.fn.stdpath("data"), "nix", "repos", clone_dir_name(spec))
		vim.fn.mkdir(vim.fn.fnamemodify(clone_dir, ":h"), "p")

		local cmd
		if exists(clone_dir) then
			cmd = { "git", "-C", clone_dir, "pull", "--ff-only" }
		else
			cmd = { "git", "clone", "--filter=blob:none", spec.url, clone_dir }
		end

		vim.system(cmd, { text = true }, function(proc)
			vim.schedule(function()
				if proc.code ~= 0 then
					local action = exists(clone_dir) and "update" or "clone"
					vim.notify(
						("nix.nvim: failed to %s %s\n%s"):format(action, spec.url, proc.stderr or ""),
						vim.log.levels.ERROR
					)
					cb(nil)
					return
				end

				local root = resolve_plugin_root(clone_dir, spec.name) or clone_dir
				local opt_dir = ensure_pack_dir()
				local link_path = join(opt_dir, spec.name)
				if exists(link_path) then
					vim.fn.delete(link_path, "rf")
				end

				local ok, err = uv.fs_symlink(root, link_path)
				if not ok then
					vim.notify(
						("nix.nvim: failed to link %s -> %s (%s)"):format(link_path, root, err or "unknown"),
						vim.log.levels.ERROR
					)
					cb(nil)
					return
				end

				cb(link_path)
			end)
		end)
		return
	end

	local target = (spec.nixpkgs or "nixpkgs") .. "#vimPlugins." .. spec.name
	util.build_async({
		target = target,
		error_prefix = "nix.nvim",
	}, function(out_path)
		if not out_path then
			cb(nil)
			return
		end

		local root = resolve_plugin_root(out_path, spec.name)
		if not root then
			vim.notify(
				("nix.nvim: could not locate runtime directory for %s in %s"):format(spec.name, out_path),
				vim.log.levels.ERROR
			)
			cb(nil)
			return
		end

		local opt_dir = ensure_pack_dir()
		local link_path = join(opt_dir, spec.name)
		if exists(link_path) then
			vim.fn.delete(link_path, "rf")
		end

		local ok, err = uv.fs_symlink(root, link_path)
		if not ok then
			vim.notify(
				("nix.nvim: failed to link %s -> %s (%s)"):format(link_path, root, err or "unknown"),
				vim.log.levels.ERROR
			)
			cb(nil)
			return
		end

		cb(link_path)
	end)
end

local function normalize_spec(input)
	if type(input) == "string" then
		return { name = input, source = "nixpkgs", lazy = false, async = true, dependencies = {} }
	end

	local spec = vim.deepcopy(input)
	local explicit_name = type(spec.name) == "string" and spec.name ~= ""
	local identifier = spec[1]
	spec[1] = nil
	spec.source = spec.source or (spec.github and "github" or "nixpkgs")

	if spec.source == "github" then
		spec.repo = spec.repo or spec.github or identifier or spec.name
		if type(spec.repo) ~= "string" or spec.repo == "" then
			error("nix.nvim: github plugin spec must provide an owner/repo identifier")
		end
		spec.repo = spec.repo:gsub("%.git$", "")
		if not explicit_name then
			spec.name = github_repo_name(spec.repo)
		end
		if spec.url == nil then
			spec.url = ("https://github.com/%s.git"):format(spec.repo)
		end
	elseif spec.source == "nixpkgs" then
		spec.name = spec.name or identifier
	else
		error(("nix.nvim: unsupported plugin source '%s'"):format(tostring(spec.source)))
	end

	if type(spec.name) ~= "string" or spec.name == "" then
		error("nix.nvim: plugin spec must have a plugin name")
	end

	if spec.lazy == nil then
		spec.lazy = false
	end
	if spec.async == nil then
		spec.async = true
	end

	spec.dependencies = listify(spec.dependencies)
	local deps = {}
	for _, dep in ipairs(spec.dependencies) do
		table.insert(deps, normalize_spec(dep))
	end
	spec.dependencies = deps

	return spec
end

local function register_spec(spec)
	local existing = state.specs[spec.name]
	if existing then
		state.specs[spec.name] = vim.tbl_deep_extend("force", existing, spec)
	else
		state.specs[spec.name] = spec
		table.insert(state.order, spec.name)
	end

	for _, dep in ipairs(spec.dependencies) do
		register_spec(dep)
	end
end

local function ensure_installed(spec, opts)
	opts = opts or {}
	if not opts.force and state.installed[spec.name] and exists(state.installed[spec.name]) then
		return state.installed[spec.name]
	end

	if not opts.force then
		local link_path = existing_link(spec)
		if link_path then
			state.installed[spec.name] = link_path
			return link_path
		end
	end

	local link_path = build_plugin(spec)
	if link_path then
		state.installed[spec.name] = link_path
	end
	return link_path
end

local function emit_plugin_loaded(name)
	if state.emitted_loaded[name] then
		return
	end
	state.emitted_loaded[name] = true

	local callbacks = state.on_loaded[name] or {}
	state.on_loaded[name] = nil
	for _, cb in ipairs(callbacks) do
		pcall(cb, name)
	end

	vim.api.nvim_exec_autocmds("User", {
		pattern = "NixPluginLoaded",
		data = { name = name },
	})
end

local function ensure_installed_async(spec, cb, opts)
	opts = opts or {}
	if not opts.force and state.installed[spec.name] and exists(state.installed[spec.name]) then
		cb(state.installed[spec.name])
		return
	end

	if not opts.force then
		local link_path = existing_link(spec)
		if link_path then
			state.installed[spec.name] = link_path
			cb(link_path)
			return
		end
	end

	if state.installing[spec.name] then
		table.insert(state.installing[spec.name], cb)
		return
	end

	state.installing[spec.name] = { cb }
	if opts.force then
		local link_path = plugin_link_path(spec.name)
		if exists(link_path) then
			vim.fn.delete(link_path, "rf")
		end
		state.installed[spec.name] = nil
	end

	build_plugin_async(spec, function(link_path)
		if link_path then
			state.installed[spec.name] = link_path
		end

		local callbacks = state.installing[spec.name] or {}
		state.installing[spec.name] = nil
		for _, callback in ipairs(callbacks) do
			pcall(callback, link_path)
		end
	end)
end

function M.load(name)
	local spec = state.specs[name]
	if not spec then
		vim.notify(("nix.nvim: unknown plugin '%s'"):format(name), vim.log.levels.WARN)
		return false
	end

	if state.loaded[name] then
		return true
	end
	if state.loading[name] then
		return true
	end

	state.loading[name] = true
	for _, dep in ipairs(spec.dependencies or {}) do
		if not M.load(dep.name) then
			state.loading[name] = nil
			return false
		end
	end

	if not ensure_installed(spec) then
		state.loading[name] = nil
		return false
	end

	vim.cmd("packadd " .. vim.fn.fnameescape(name))
	state.loaded[name] = true
	state.loading[name] = nil

	if type(spec.config) == "function" then
		local ok, err = pcall(spec.config)
		if not ok then
			vim.notify(("nix.nvim: config failed for %s\n%s"):format(name, err), vim.log.levels.ERROR)
			return false
		end
	end

	emit_plugin_loaded(name)

	return true
end

function M.load_async(name, cb)
	local spec = state.specs[name]
	if not spec then
		vim.notify(("nix.nvim: unknown plugin '%s'"):format(name), vim.log.levels.WARN)
		if cb then
			cb(false)
		end
		return
	end

	if state.loaded[name] then
		if cb then
			cb(true)
		end
		return
	end

	if state.loading_async[name] then
		if cb then
			table.insert(state.loading_async[name], cb)
		end
		return
	end

	state.loading_async[name] = {}
	if cb then
		table.insert(state.loading_async[name], cb)
	end

	local function finish(ok)
		local callbacks = state.loading_async[name] or {}
		state.loading_async[name] = nil
		if ok then
			state.loaded[name] = true
			emit_plugin_loaded(name)
		end
		for _, callback in ipairs(callbacks) do
			pcall(callback, ok)
		end
	end

	local deps = spec.dependencies or {}
	local i = 1
	local function load_next_dependency()
		if i > #deps then
			ensure_installed_async(spec, function(link_path)
				if not link_path then
					finish(false)
					return
				end

				vim.cmd("packadd " .. vim.fn.fnameescape(name))
				if type(spec.config) == "function" then
					local ok, err = pcall(spec.config)
					if not ok then
						vim.notify(("nix.nvim: config failed for %s\n%s"):format(name, err), vim.log.levels.ERROR)
						finish(false)
						return
					end
				end

				finish(true)
			end)
			return
		end

		local dep = deps[i]
		i = i + 1
		M.load_async(dep.name, function(ok)
			if not ok then
				finish(false)
				return
			end
			load_next_dependency()
		end)
	end

	load_next_dependency()
end

function M.update(name)
	local names = {}
	if name and name ~= "" then
		if not state.specs[name] then
			vim.notify(("nix.nvim: unknown plugin '%s'"):format(name), vim.log.levels.WARN)
			return
		end
		names = { name }
	else
		names = vim.deepcopy(state.order)
	end

	if #names == 0 then
		vim.notify("nix.nvim: no plugins configured", vim.log.levels.INFO)
		return
	end

	vim.notify(("nix.nvim: updating %d plugin(s) in background"):format(#names), vim.log.levels.INFO)
	local i = 1
	local updated = 0
	local failed = 0
	local function next_update()
		if i > #names then
			vim.notify(("nix.nvim: update complete (%d ok, %d failed)"):format(updated, failed), vim.log.levels.INFO)
			return
		end

		local plugin_name = names[i]
		i = i + 1
		ensure_installed_async(state.specs[plugin_name], function(link_path)
			if link_path then
				updated = updated + 1
			else
				failed = failed + 1
			end
			next_update()
		end, { force = true })
	end

	next_update()
end

function M.status()
	local lines = { "nix.nvim plugin status:" }
	for _, name in ipairs(state.order) do
		local installed = existing_link(state.specs[name]) ~= nil
		local loaded = state.loaded[name] == true
		local marker = installed and "installed" or "missing"
		if loaded then
			marker = marker .. ", loaded"
		end
		table.insert(lines, ("- %s: %s"):format(name, marker))
	end
	if #state.order == 0 then
		table.insert(lines, "- (no plugins configured)")
	end
	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

function M.has_spec(name)
	return state.specs[name] ~= nil
end

function M.is_loaded(name)
	return state.loaded[name] == true
end

function M.on_plugin_loaded(name, cb)
	if type(cb) ~= "function" then
		return
	end
	if M.is_loaded(name) then
		cb(name)
		return
	end
	state.on_loaded[name] = state.on_loaded[name] or {}
	table.insert(state.on_loaded[name], cb)
end

function M.list_installed()
	local lines = { "nix.nvim installed plugins:" }
	local count = 0
	for _, name in ipairs(state.order) do
		if existing_link(state.specs[name]) then
			count = count + 1
			table.insert(lines, "- " .. name)
		end
	end
	if count == 0 then
		table.insert(lines, "- (none)")
	end
	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

local function setup_commands()
	if state.commands_ready then
		return
	end
	state.commands_ready = true

	vim.api.nvim_create_user_command("Nix", function(ctx)
		local args = vim.split(vim.trim(ctx.args or ""), "%s+", { trimempty = true })
		local sub = args[1]
		if sub == nil then
			M.list_installed()
			return
		end

		if sub == "status" then
			M.status()
			return
		end

		if sub == "update" then
			M.update(args[2])
			return
		end

		vim.notify("nix.nvim: usage: :Nix [status|update [plugin-name]]", vim.log.levels.WARN)
	end, {
		nargs = "*",
		complete = function(_, _, _)
			return { "status", "update" }
		end,
	})
end

local function register_lazy(spec)
	if not spec.lazy then
		return
	end
	local function load_spec(cb)
		if spec.async then
			M.load_async(spec.name, cb)
			return
		end
		local ok = M.load(spec.name)
		if cb then
			cb(ok)
		end
	end

	for _, cmd in ipairs(listify(spec.cmd)) do
		vim.api.nvim_create_user_command(cmd, function(ctx)
			load_spec(function(ok)
				if not ok then
					return
				end
				pcall(vim.api.nvim_del_user_command, cmd)
				local line = ctx.name
				if ctx.bang then
					line = line .. "!"
				end
				if ctx.args ~= "" then
					line = line .. " " .. ctx.args
				end
				vim.cmd(line)
			end)
		end, { nargs = "*", bang = true, desc = ("lazy-load %s"):format(spec.name) })
	end

	for _, key in ipairs(listify(spec.keys)) do
		local mode, lhs, rhs, opts
		if type(key) == "string" then
			mode, lhs, rhs, opts = "n", key, nil, {}
		else
			mode = key.mode or "n"
			lhs = key[1]
			rhs = key[2]
			opts = key.opts or {}
		end

		if lhs then
			vim.keymap.set(mode, lhs, function()
				load_spec(function(ok)
					if not ok then
						return
					end
					pcall(vim.keymap.del, mode, lhs)
					if type(rhs) == "function" then
						rhs()
					elseif type(rhs) == "string" then
						vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(rhs, true, false, true), "m", false)
					else
						vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, false, true), "m", false)
					end
				end)
			end, opts)
		end
	end

	if spec.ft then
		vim.api.nvim_create_autocmd("FileType", {
			pattern = listify(spec.ft),
			once = true,
			callback = function()
				load_spec()
			end,
		})
	end

	local events = listify(spec.event)
	if #events == 0 and not spec.ft and not spec.cmd and not spec.keys then
		events = { "VimEnter" }
	end
	if #events > 0 then
		vim.api.nvim_create_autocmd(events, {
			once = true,
			callback = function()
				load_spec()
			end,
		})
	end
end

function M.install(name)
	local spec = state.specs[name]
	if not spec then
		vim.notify(("nix.nvim: unknown plugin '%s'"):format(name), vim.log.levels.WARN)
		return false
	end
	return ensure_installed(spec) ~= nil
end

function M.setup(opts)
	opts = opts or {}
	if opts.nixpkgs and type(opts.nixpkgs) == "string" then
		state.default_nixpkgs = opts.nixpkgs
	end
	util.set_default_nixpkgs(state.default_nixpkgs)

	for _, plugin in ipairs(collect_import_specs(opts.import)) do
		register_spec(normalize_spec(plugin))
	end
	for _, plugin in ipairs(listify(opts.plugins)) do
		register_spec(normalize_spec(plugin))
	end

	for _, name in ipairs(state.order) do
		local spec = state.specs[name]
		spec.nixpkgs = spec.nixpkgs or state.default_nixpkgs
	end

	setup_commands()

	for _, name in ipairs(state.order) do
		local spec = state.specs[name]
		if type(spec.init) == "function" then
			local ok, err = pcall(spec.init)
			if not ok then
				vim.notify(("nix.nvim: init failed for %s\n%s"):format(name, err), vim.log.levels.ERROR)
			end
		end
	end

	for _, name in ipairs(state.order) do
		local spec = state.specs[name]
		if spec.lazy then
			register_lazy(spec)
		elseif spec.async then
			M.load_async(name)
		else
			M.load(name)
		end
	end
end

return M

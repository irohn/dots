local M = {}

---@param pkg string
---@param cmd? string|string[]
---@param nixpkgs? { url: string, allow_unfree?: boolean }
---@return string[]|nil argv  -- list of args or nil on error
---@return string? err
function M.build_nix_shell_cmd(pkg, cmd, nixpkgs)
  if type(pkg) ~= "string" or pkg == "" then
    return nil, "Package must be a non-empty string"
  end

  nixpkgs = nixpkgs or {
    url = "nixpkgs",
    allow_unfree = true,
  }
  cmd = cmd or pkg

  -- Base command
  local argv = {
    "nix",
    "--experimental-features", "nix-command flakes",
    "shell",
  }

  if nixpkgs.allow_unfree then
    argv[#argv + 1] = "--impure"
  end

  argv[#argv + 1] = string.format("%s#%s", nixpkgs.url, pkg)
  argv[#argv + 1] = "--command"

  local t = type(cmd)
  if t == "string" then
    argv[#argv + 1] = cmd
  elseif t == "table" then
    vim.list_extend(argv, cmd)
  else
    return nil, ("Invalid cmd type (%s); must be string or list of strings"):format(t)
  end

  return argv
end

return M

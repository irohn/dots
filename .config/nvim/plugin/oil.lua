local ok, oil = pcall(require, "oil")
if not ok then return end

oil.setup({
  win_options = {
    signcolumn = "yes:1",
    number = false,
    relativenumber = false,
  },
  keymaps = {
    ["gd"] = {
      desc = "Toggle file detail view",
      callback = (function()
        local detail = false
        return function()
          detail = not detail
          if detail then
            require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
          else
            require("oil").set_columns({ "icon" })
          end
        end
      end)(),
    },
  },
  view_options = {
    show_hidden = true,
    is_always_hidden = function(name, _)
      local hidden_dirs = { "..", ".git", ".direnv" }
      for _, dir in ipairs(hidden_dirs) do
        if name == dir then
          return true
        end
      end
      return false
    end,
  },
  float = {
    max_width = 0.5,
    max_height = 0.5,
    border = "rounded",
  },
})

vim.keymap.set("n", "-", function()
  require("oil").open()
end)

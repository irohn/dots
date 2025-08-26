local ok, treesitter = pcall(require, "nvim-treesitter")
if not ok then return end

treesitter.install({
  "c",
  "lua",
  "vim",
  "vimdoc",
  "query",
  "markdown",
  "markdown_inline"
})

-- Auto update treesitter parsers when nvim-treesitter is updated
vim.api.nvim_create_autocmd("PackChanged", {
  pattern = "*",
  callback = function(ev)
    vim.notify(ev.data.spec.name .. " has been updated.")
    if ev.data.spec.name == "nvim-treesitter" and ev.data.spec.kind ~= "deleted" then
      vim.cmd("TSUpdate")
    end
  end,
})

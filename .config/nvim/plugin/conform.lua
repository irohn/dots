require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "isort", "black" },
  },
})

vim.keymap.set("n", "<c-f>", function()
  require("conform").format({ lsp_fallback = true })
end, { noremap = true, silent = true, desc = "Format current buffer" })

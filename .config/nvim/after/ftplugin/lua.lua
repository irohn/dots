vim.keymap.set("n", "<leader>w", ":w | source %<cr>")

vim.treesitter.start()
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

-- vim: ts=2 sts=2 sw=2 et

vim.bo.shiftwidth = 2
vim.bo.tabstop = 2
vim.bo.softtabstop = 2
vim.bo.expandtab = true
vim.treesitter.start()
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

vim.keymap.set("n", "<leader>r", "<cmd>write | source %<cr>", { buffer = true, silent = true })

-- vim: ts=2 sts=2 sw=2 et

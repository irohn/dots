vim.bo.shiftwidth = 4
vim.bo.tabstop = 4
vim.bo.softtabstop = 4
vim.bo.expandtab = true

vim.bo.makeprg = "python3 %"
vim.keymap.set("n", "<leader>w", "<cmd>make<cr>", { buffer = true, silent = true })

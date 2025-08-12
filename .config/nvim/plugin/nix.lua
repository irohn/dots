require("nix").setup()

vim.keymap.set("n", "<leader>l", require("nix").lsp.toggle)

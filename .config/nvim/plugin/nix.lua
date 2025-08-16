require("nix").setup({
  lsp = {
    enabled = true,
  },
  nixpkgs = {
    allow_unfree = true,
  },
})

vim.keymap.set("n", "<leader>l", require("nix").lsp.toggle)

if vim.fn.has('nvim-0.12') ~= 1 then
  return
end

require("copilot").setup({
  suggestion = {
    auto_trigger = true,
    keymap = {
      accept = "<s-tab>",
      dismiss = "<c-c>",
    },
  },
})

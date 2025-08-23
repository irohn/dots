if vim.fn.has('nvim-0.12') ~= 1 then
  return
end

local snacks = require("snacks")

snacks.setup({
  bigfile = { enabled = true },
  input = { enabled = true },
  picker = { enabled = true },
})

vim.keymap.set("n", "<leader>/", snacks.picker.lines)
vim.keymap.set("n", "<leader>:", snacks.picker.command_history)
vim.keymap.set("n", "<leader>fb", snacks.picker.buffers)
vim.keymap.set("n", "<leader>ff", snacks.picker.files)
vim.keymap.set("n", "<leader>fg", snacks.picker.grep)
vim.keymap.set("n", "<leader>fh", snacks.picker.help)
vim.keymap.set("n", "<leader>fk", snacks.picker.keymaps)
vim.keymap.set("n", "<leader>fm", snacks.picker.marks)
vim.keymap.set("n", "<leader>fq", snacks.picker.qflist)
vim.keymap.set("n", "<leader>fs", snacks.picker.search_history)
vim.keymap.set("n", "<leader>fu", snacks.picker.undo)
vim.keymap.set("n", "<leader>th", snacks.picker.colorschemes)

vim.keymap.set("n", "<leader>sD", snacks.picker.diagnostics)
vim.keymap.set("n", "<leader>sd", snacks.picker.diagnostics_buffer)

vim.keymap.set("n", "<leader>gL", snacks.picker.git_log)
vim.keymap.set("n", "<leader>gS", snacks.picker.git_stash)
vim.keymap.set("n", "<leader>gb", snacks.picker.git_branches)
vim.keymap.set("n", "<leader>gd", snacks.picker.git_diff)
vim.keymap.set("n", "<leader>gf", snacks.picker.git_log_file)
vim.keymap.set("n", "<leader>gl", snacks.picker.git_log_line)
vim.keymap.set("n", "<leader>gs", snacks.picker.git_status)

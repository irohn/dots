vim.g.mapleader = " "

vim.o.clipboard = "unnamedplus"
vim.o.cursorline = true
vim.o.expandtab = true
vim.o.ignorecase = true
vim.o.inccommand = "split"
vim.o.linebreak = true
vim.o.signcolumn = "yes"
vim.o.smartcase = true
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.termguicolors = true
vim.o.undofile = true
vim.o.virtualedit = "block"
vim.o.winborder = "rounded"
vim.o.wrap = false
vim.opt.completeopt:append({ "menuone", "noselect", "noinsert", "preview" })

vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("n", "<esc>", "<cmd>nohlsearch<cr><esc>")
vim.keymap.set("n", "<c-u>", "<c-u>zz")
vim.keymap.set("n", "<c-d>", "<c-d>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>")
vim.keymap.set("n", "-", vim.cmd.Explore)

local augroup = function(name)
  return vim.api.nvim_create_augroup("custom." .. name, { clear = true })
end

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight-on-yank"),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("auto-resize"),
  callback = function()
    vim.schedule(function()
      local current_tab = vim.api.nvim_get_current_tabpage()
      vim.cmd("tabdo wincmd =") -- Resize all windows on all tabs
      vim.api.nvim_set_current_tabpage(current_tab)
    end)
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup("disable-newline-comments"),
  callback = function()
    vim.opt.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- persistent colorscheme
_G.get_colorscheme = function(fallback)
  if not vim.g.COLORS_NAME then
    vim.cmd.rshada()
  end
  if not vim.g.COLORS_NAME or vim.g.COLORS_NAME == "" then
    return fallback or "default"
  end
  return vim.g.COLORS_NAME
end

_G.save_colorscheme = function(colorscheme)
  colorscheme = colorscheme or vim.g.colors_name
  if get_colorscheme() == colorscheme then
    return
  end
  vim.g.COLORS_NAME = colorscheme
  vim.cmd.wshada()
end

vim.api.nvim_create_autocmd("VimEnter", {
  group = augroup("load-persistent-colorscheme"),
  callback = function()
    pcall(vim.cmd.colorscheme, get_colorscheme())
    return vim.g.colors_name == get_colorscheme("default")
  end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  group = augroup("save-colorscheme-after-change"),
  callback = function()
    save_colorscheme(vim.g.colors_name)
  end,
})

-- lsp
vim.lsp.enable({
  "ansiblels",
  "basedpyright",
  "bashls",
  "cssls",
  "docker_language_server",
  "earthlyls",
  "gopls",
  "helm_ls",
  "html",
  "jsonls",
  "lua_ls",
  "nixd",
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client ~= nil and client:supports_method("textDocument/completion") then
      -- autocomplete
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end
  end,
})

vim.keymap.set("n", "<c-f>", vim.lsp.buf.format)
vim.keymap.set("n", "gd", vim.lsp.buf.definition)

-- plugins
vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/zbirenbaum/copilot.lua",
  "https://github.com/olimorris/codecompanion.nvim",
  "https://github.com/ravitemer/mcphub.nvim",
  "https://github.com/folke/snacks.nvim",
})

vim.api.nvim_create_autocmd("PackChanged", {
  group = augroup("plugins-update"),
  callback = function()
    local ok, _ = pcall(vim.cmd("TSUpdate"))
    if not ok then
      vim.notify("Treesitter update failed", vim.log.levels.ERROR)
    end
  end,
})

require("nvim-treesitter").install({
  "markdown",
  "markdown_inline",
  "lua",
  "yaml",
}):wait(300000) -- wait max 5 minutes

local snacks = require("snacks")
snacks.setup({
  bigfile = { enabled = true },
  picker = { enabled = true },
  input = { enabled = true },
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
vim.keymap.set("n", "<leader>gL", snacks.picker.git_log)
vim.keymap.set("n", "<leader>gS", snacks.picker.git_stash)
vim.keymap.set("n", "<leader>gb", snacks.picker.git_branches)
vim.keymap.set("n", "<leader>gd", snacks.picker.git_diff)
vim.keymap.set("n", "<leader>gf", snacks.picker.git_log_file)
vim.keymap.set("n", "<leader>gl", snacks.picker.git_log_line)
vim.keymap.set("n", "<leader>gs", snacks.picker.git_status)
vim.keymap.set("n", "<leader>sD", snacks.picker.diagnostics)
vim.keymap.set("n", "<leader>sd", snacks.picker.diagnostics_buffer)
vim.keymap.set("n", "<leader>th", snacks.picker.colorschemes)

require("copilot").setup({
  suggestion = {
    auto_trigger = true,
    keymap = {
      accept = "<s-tab>",
      dismiss = "<c-c>",
    },
  },
})

require("codecompanion").setup({
  display = {
    chat = {
      show_settings = true,
    },
  },
  extensions = {
    mcphub = {
      callback = "mcphub.extensions.codecompanion",
      opts = {
        make_vars = true,
        make_slash_commands = true,
        show_result_in_chat = true
      }
    }
  }
})
vim.keymap.set({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
vim.keymap.set("v", "<leader>ae", ":CodeCompanion ", { noremap = true, silent = false })
vim.keymap.set({ "n", "v" }, "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
vim.keymap.set("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true })

-- vim: ts=2 sts=2 sw=2 et

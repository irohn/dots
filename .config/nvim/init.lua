vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.o.breakindent = true
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
vim.opt.path:append({ "**" })

vim.keymap.set("n", "<leader>/", function()
  local cmd = ":vimgrep // % | copen"
  local lefts = string.rep("<Left>", #cmd - cmd:find("/"))
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(cmd .. lefts, true, false, true), "n", true)
end, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>fg", function()
  local cmd = ":vimgrep // ** | copen"
  local lefts = string.rep("<Left>", #cmd - cmd:find("/"))
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(cmd .. lefts, true, false, true), "n", true)
end, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>ff", ":find *")
vim.keymap.set("n", "<leader>fb", ":b *")
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("n", "<esc>", "<cmd>nohlsearch<cr><esc>")
vim.keymap.set("n", "<c-u>", "<c-u>zz")
vim.keymap.set("n", "<c-d>", "<c-d>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>")
vim.keymap.set("n", "-", vim.cmd.Explore)

_G.augroup = function(name)
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

vim.keymap.set("n", "<leader>q", function()
  local is_qf_open = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "quickfix" then
      is_qf_open = true
      break
    end
  end
  vim.cmd(is_qf_open and "cclose" or "copen")
end, { noremap = true, silent = true })

-- netrw
-- credit: https://github.com/tpope/vim-vinegar
vim.g.netrw_list_hide = [[\(^\|\s\s\)\zs\.\S\+]]
vim.g.netrw_banner = 0
vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function()
    vim.keymap.set("n", "-", function()
      local dir = vim.b.netrw_curdir or vim.fn.expand("%:h")
      vim.cmd("edit " .. vim.fn.fnamemodify(dir, ":h"))
    end, { buffer = true, silent = true })
    vim.keymap.set("n", "~", ":edit ~/<CR>", { buffer = true, silent = true })
  end,
})

-- persistent colorscheme
-- credit:
-- https://github.com/folke/snacks.nvim/discussions/1239#discussioncomment-12555681
local get_colorscheme = function(fallback)
  if not vim.g.COLORS_NAME then
    vim.cmd.rshada()
  end
  if not vim.g.COLORS_NAME or vim.g.COLORS_NAME == "" then
    return fallback or "default"
  end
  return vim.g.COLORS_NAME
end

local save_colorscheme = function(colorscheme)
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

-- native package management (Neovim 0.12+)
if vim.fn.has('nvim-0.12') == 1 then
  vim.pack.add({
    { src = "https://github.com/nvim-lua/plenary.nvim",           version = "master" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    { src = "https://github.com/zbirenbaum/copilot.lua" },
    { src = "https://github.com/olimorris/codecompanion.nvim" },
    { src = "https://github.com/ravitemer/mcphub.nvim" },
    { src = "https://github.com/irohn/nix.nvim" },
  })
end

local nix_ok, nix = pcall(require, "nix")
if nix_ok then
  nix.setup({
    plugin_manager = {
      plugins = {
        { pkg = "vimPlugins.oil-nvim" },
        { pkg = "vimPlugins.snacks-nvim" },
      },
    },
    lsp_manager = {
      enabled = {
        "lua_ls",
        "bashls",
        "nixd"
      },
    }
  })
  vim.keymap.set("n", "<leader>P", require("nix.plugin-manager.ui").open, { noremap = true, silent = true })
  vim.keymap.set("n", "<leader>L", require("nix.lsp-manager.ui").open, { noremap = true, silent = true })
end

-- lsp
if vim.fn.has('nvim-0.11') == 1 then
  vim.keymap.set("n", "<c-f>", vim.lsp.buf.format)
  vim.keymap.set("n", "gd", vim.lsp.buf.definition)

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client ~= nil and client:supports_method("textDocument/completion") then
        vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
      end
    end,
  })
end

-- vim: ts=2 sts=2 sw=2 et

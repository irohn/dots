-- globals
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- options
vim.o.breakindent = true
vim.o.cursorline = true
vim.o.expandtab = true
vim.o.ignorecase = true
vim.o.inccommand = "split"
vim.o.number = true
vim.o.laststatus = 3
vim.o.linebreak = true
vim.o.scrolloff = 8
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

-- keymaps
local function vimgrep_prompt(scope)
  local cmd = (":vimgrep // %s | copen"):format(scope)
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(cmd .. string.rep("<Left>", #scope + 10), true, false, true),
    "n",
    true
  )
end

vim.keymap.set("n", "<leader>/", function()
  vimgrep_prompt("%")
end, { silent = true })
vim.keymap.set("n", "<leader>fg", function()
  vimgrep_prompt("**")
end, { silent = true })
vim.keymap.set("n", "<leader>ff", ":find *")
vim.keymap.set("n", "<leader>fb", ":b *")
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("n", "<esc>", "<cmd>nohlsearch<cr><esc>")
vim.keymap.set("n", "<c-u>", "<c-u>zz")
vim.keymap.set("n", "<c-d>", "<c-d>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set({ "n", "v" }, "<leader>p", '"+p')
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y')
vim.keymap.set("n", "<leader>r", "<cmd>make<cr>")
vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>")
vim.keymap.set("t", "<c-w>", "<c-\\><c-n><c-w>")
vim.keymap.set("n", "-", vim.cmd.Explore)
vim.keymap.set("n", "<leader>qf", function()
  vim.cmd((vim.fn.getqflist({ winid = 0 }).winid ~= 0) and "cclose" or "copen")
end, { silent = true })
vim.keymap.set("n", "<c-f>", vim.lsp.buf.format)

-- autocmds
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("irohn/highlight-on-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("VimResized", {
  group = vim.api.nvim_create_augroup("irohn/auto-resize", { clear = true }),
  callback = function()
    vim.schedule(function()
      local current_tab = vim.api.nvim_get_current_tabpage()
      vim.cmd("tabdo wincmd =") -- Resize all windows on all tabs
      vim.api.nvim_set_current_tabpage(current_tab)
    end)
  end,
})

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
local saved_colorscheme_file = vim.fn.stdpath("state") .. "/last_colorscheme"
local file_exists = vim.fn.filereadable(saved_colorscheme_file) == 1
if not file_exists then
  vim.fn.writefile({ "default" }, saved_colorscheme_file)
end
_G.saved_colorscheme = vim.fn.readfile(saved_colorscheme_file)[1] or "default"

-- plugin management
require("config.lazy")

-- set colorscheme
pcall(vim.cmd.colorscheme, saved_colorscheme)
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    pcall(vim.fn.writefile, { vim.g.colors_name }, saved_colorscheme_file)
  end,
})

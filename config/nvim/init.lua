-- basic setting
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.cursorline = true
vim.api.nvim_set_hl(0, 'CursorLine', {})

-- indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

-- search setting
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- visual setting
vim.opt.termguicolors = true
vim.opt.showmode = false

-- file handing
vim.opt.backup = false
vim.opt.updatetime = 300
vim.opt.autoread = true
vim.opt.undofile = true

-- behavior setting
vim.opt.hidden = true
vim.opt.errorbells = false
vim.opt.backspace = "indent,eol,start"
vim.opt.autochdir = false
vim.opt.mouse = "a"
vim.opt.modifiable = true
vim.opt.encoding = "UTF-8"

-- center screen when jumping
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

-- key mapping
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- better indenting in visual mode
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

-- return to last edit position when opening files
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- open config
vim.keymap.set("n", "<leader>c", ":e ~/.config/nvim<CR>", { desc = "Configuration" })

-- Performance improvements
vim.opt.redrawtime = 10000
vim.opt.maxmempattern = 20000

-- buffer navigation
vim.keymap.set("n", "<tab>", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-tab>", ":bprevious<CR>", { desc = "Previous buffer" })

vim.keymap.set({ "n", "v", "o" }, "L", "$")
vim.keymap.set({ "n", "v", "o" }, "H", "^")

-- Open help in the current window as a normal listed buffer
vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  callback = function()
    vim.bo.buflisted = true -- make it show in bufferline and :bnext
    vim.bo.buftype = ""     -- treat as a normal buffer
    vim.cmd("wincmd o")     -- close any other windows in this tab
  end
})

if vim.fn.has('wsl') == 1 then
  vim.g.clipboard = {
    name = 'WslClipboard',
    copy = {
      ['+'] = 'clip.exe',
    },
    paste = {
      ['+'] = '/usr/bin/win32yank',
    },
    cache_enabled = 0,
  }
elseif vim.env.SSH_CONNECTION then
  vim.g.clipboard = {
    name = "osc52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
end

vim.keymap.set({ "n", "v" }, "Y", '"+y', { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "YY", '"+yy', { noremap = true, silent = true })

-- highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.keymap.set('n', '<leader>q', function()
  local listed_buffers = vim.fn.getbufinfo({ buflisted = 1 })

  if #listed_buffers <= 1 then
    vim.cmd('quit')
  else
    vim.cmd('bdelete')
  end
end, { desc = 'Close buffer or quit' })

vim.opt.diffopt:append("vertical")

require("config.lazy")

vim.keymap.set('n', '<leader>h', '<cmd>lua vim.lsp.buf.hover()<cr>')
vim.keymap.set('n', '<leader>r', '<cmd>lua vim.lsp.buf.rename()<cr>')
vim.keymap.set({ 'n', 'x' }, '<leader>F', '<cmd>lua vim.lsp.buf.format({async = true})<cr>')

vim.lsp.config('*', {
  capabilities = {
    textDocument = {
      semanticTokens = {
        multilineTokenSupport = true,
      }
    }
  },
  root_markers = { '.git' },
})

vim.diagnostic.config({
  signs = false,
  virtual_text = true,
})

vim.lsp.enable({
  "lua_ls",
  "clangd",
  "pyright",
  "ltex_plus",
  "bashls"
})


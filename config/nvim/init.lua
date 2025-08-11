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

-- visual setting
vim.opt.termguicolors = true
vim.opt.completeopt = "menu,menuone,noinsert,noselect,fuzzy"
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
vim.g.maplocalleader = " "

-- smart window split
local function smart_split_ratio()
    local w = vim.api.nvim_win_get_width(0)
    local h = vim.api.nvim_win_get_height(0)

    if 8 * w - 20 * h < 0 then
        vim.cmd("belowright split")
    else
        vim.cmd("rightbelow vsplit")
    end
end

vim.keymap.set("n", "<leader>w", smart_split_ratio, { desc = "Smart window split" })

vim.keymap.set("n", "<leader>q", function()
  local buf_count = 0
  -- Count how many listed buffers are currently open
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, "buflisted") then
      buf_count = buf_count + 1
    end
  end

  if vim.bo.modifiable and not vim.bo.readonly then
    vim.cmd("w")  -- save current buffer
  end

  if buf_count > 1 then
    -- More than one buffer open, just close current buffer
    vim.cmd("bdelete!")
  else
    -- Only one buffer left, quit Vim
    vim.cmd("quit!")
  end
end, { desc = "Smart save and quit buffer or window" })

-- save window and buffer when focus change
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "WinLeave" }, {
  callback = function()
    if vim.bo.modifiable and vim.bo.buftype == "" and vim.bo.filetype ~= "" and vim.fn.expand("%") ~= "" then
      vim.cmd("silent! update")  
    end
  end,
  desc = "Auto save on buffer/window/focus leave",
})

-- better window navigation
vim.keymap.set({ "n", "t" }, "<A-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set({ "n", "t" }, "<A-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set({ "n", "t" }, "<A-k>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set({ "n", "t" }, "<A-l>", "<C-w>l", { desc = "Move to right window" })

-- splitting window
vim.keymap.set("n", "<leader>|", ":vsplit<CR>", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>-", ":vsplit<CR>", { desc = "Split window horizontally" })

-- resize window
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-Right>", ":vercital resize +2<CR>", { desc = "Increase window width" })

-- insert mode move
vim.keymap.set('i', '<C-h>', '<Left>', { noremap = true })
vim.keymap.set('i', '<C-j>', '<Down>', { noremap = true })
vim.keymap.set('i', '<C-k>', '<Up>', { noremap = true })
vim.keymap.set('i', '<C-l>', '<Right>', { noremap = true })

-- toggle terminal
vim.keymap.set("n", "<leader>t", function()
  local curr_buftype = vim.bo.buftype

  if curr_buftype == "terminal" then
    local curr_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_close(curr_win, true)
    return
  end

  local term_win = nil
  local term_buf = nil

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buftype == "terminal" then
      term_win = win
      break
    end
  end

  if term_win then
    vim.api.nvim_set_current_win(term_win)
    return
  end

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buftype == "terminal" then
      term_buf = bufnr
      break
    end
  end

  if term_buf then
    vim.cmd("belowright split")
    vim.api.nvim_set_current_buf(term_buf)
  else
    vim.cmd("belowright split | terminal")
  end
end, { desc = "Toggle terminal" })

-- auto close terminal when only terminal
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local wins = vim.api.nvim_list_wins()
    local only_terminal = true

    for _, win in ipairs(wins) do
      local buf = vim.api.nvim_win_get_buf(win)
      local bt = vim.api.nvim_buf_get_option(buf, "buftype")
      if bt ~= "terminal" then
        only_terminal = false
        break
      end
    end

    if only_terminal and #wins == 1 then
      vim.cmd("qa")  
    end
  end,
})

-- open terminal in insert mode
vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter" }, {
  pattern = "term://*",
  callback = function()
    if vim.bo.buftype == "terminal" then
      vim.cmd("startinsert")
    end
  end,
  desc = "Auto enter insert mode in terminal",
})

-- terminal normal mode with <Esc>
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Terminal: enter normal mode" })

-- better indenting in visual mode
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

-- highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank()
    end,
})

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

-- auto-resize splits when window is resized
vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
        vim.cmd("tabdo wincmd =") end,
})

-- create directories when saving files
vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function() 
        local dir = vim.fn.expand('<afile>:p:h')
        if vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir, 'p')
        end
    end
})

-- open config
vim.keymap.set("n", "<leader>c", ":e ~/.config/nvim<CR>", { desc = "Configuration"})

-- Performance improvements
vim.opt.redrawtime = 10000
vim.opt.maxmempattern = 20000

-- buffer navigation
vim.keymap.set("n", "L", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "H", ":bprevious<CR>", { desc = "Previous buffer" })

-- lazyvim
require("config.lazy")

-- basic setting
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.cursorline = true
vim.api.nvim_set_hl(0, 'CursorLine', {})

-- indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

-- search setting
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
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

-- insert mode move
vim.keymap.set('i', '<C-h>', '<Left>', { noremap = true })
vim.keymap.set('i', '<C-j>', '<Down>', { noremap = true })
vim.keymap.set('i', '<C-k>', '<Up>', { noremap = true })
vim.keymap.set('i', '<C-l>', '<Right>', { noremap = true })

-- 切換 terminal buffer 的功能
local function toggle_terminal()
  local term_buf
  -- 找到第一個存在的 terminal buffer
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, "buftype") == "terminal" then
      term_buf = buf
      break
    end
  end

  local current_buf = vim.api.nvim_get_current_buf()
  local current_buftype = vim.api.nvim_buf_get_option(current_buf, "buftype")

  if not term_buf then
    -- 沒有 terminal buffer，就新開一個
    vim.cmd("botright split | terminal")
    vim.cmd("startinsert")
  else
    if current_buftype == "terminal" and current_buf == term_buf then
      -- 當前已經在 terminal buffer，關閉 window 而不刪除 buffer
      vim.cmd("close")
    else
      -- terminal buffer 已存在，切換到它所在的 window
      local term_win = vim.fn.bufwinid(term_buf)
      if term_win ~= -1 then
        vim.api.nvim_set_current_win(term_win)
      else
        -- 如果 terminal buffer 沒有 window，則新開一個
        vim.cmd("botright split | terminal")
        vim.api.nvim_set_current_buf(term_buf)
      end
      vim.cmd("startinsert")
    end
  end
end

vim.keymap.set("n", "<leader>t", toggle_terminal, { noremap = true, silent = true, desc = "Toggle terminal buffer" })

-- <leader>i: 若目前在 terminal buffer，跳回原本編輯的 buffer
vim.keymap.set("n", "<leader>i", function()
  local current_buf = vim.api.nvim_get_current_buf()
  local buftype = vim.api.nvim_buf_get_option(current_buf, "buftype")
  if buftype == "terminal" then
    vim.cmd("wincmd p")
  end
end, { noremap = true, silent = true, desc = "Return to last editing buffer" })

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

-- Automatically save all modifiable normal buffers when changed
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  pattern = "*", -- apply to all buffers
  callback = function()
    local bufnr = 0
    local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
    local modifiable = vim.api.nvim_buf_get_option(bufnr, "modifiable")

    if modifiable and buftype == "" then
      -- Ensure directory exists before saving
      local file = vim.api.nvim_buf_get_name(bufnr)
      if file ~= "" then
        local dir = vim.fn.fnamemodify(file, ":p:h")
        if vim.fn.isdirectory(dir) == 0 then
          vim.fn.mkdir(dir, "p")
        end
      end
      vim.cmd("silent write")
    end
  end,
})

local function close_or_quit()
  local current_buf = vim.api.nvim_get_current_buf()
  local buftype = vim.api.nvim_buf_get_option(current_buf, "buftype")

  -- Skip unmodifiable buffers (unless it's a terminal)
  if buftype ~= "terminal" and not vim.api.nvim_buf_get_option(current_buf, "modifiable") then
    vim.notify("Buffer is not modifiable! Aborting.", vim.log.levels.WARN)
    return
  end

  local any_real_buffer = false

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and buf ~= current_buf then
      local bt = vim.api.nvim_buf_get_option(buf, "buftype")
      local name = vim.api.nvim_buf_get_name(buf)
      local is_real_buffer = name ~= "" or bt == ""
      if is_real_buffer then
        any_real_buffer = true
        break
      end
    end
  end

  if not any_real_buffer then
    vim.cmd("qa!")
  else
    if buftype ~= "terminal" then
      local file = vim.api.nvim_buf_get_name(current_buf)
      if file ~= "" then
        local dir = vim.fn.fnamemodify(file, ":p:h")
        if vim.fn.isdirectory(dir) == 0 then
          vim.fn.mkdir(dir, "p")
        end
        vim.cmd("silent write")
      end
    end
    -- Save current buffer before closing (and create dir if needed)
    vim.cmd("bdelete!")
  end
end

-- Optional: Map it to a key, e.g. <leader>q
vim.keymap.set("n", "<leader>q", close_or_quit, { desc = "Smart close or quit" })

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

vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })

vim.keymap.set("i", "<A-k>", "<Esc>:m .-2<CR>==gi", { desc = "Move line up" })
vim.keymap.set("i", "<A-j>", "<Esc>:m .+1<CR>==gi", { desc = "Move line down" })

vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })

require("config.lsp")
-- lazyvim
require("config.lazy")

-- nvim-treesitter.lua
vim.api.nvim_create_autocmd('PackChanged', { callback = function(ev)
  local name, kind = ev.data.spec.name, ev.data.kind
  if name == 'nvim-treesitter' and (kind == "install" or kind == "update") then
    if not ev.data.active then vim.cmd.packadd('nvim-treesitter') end
    vim.cmd('TSUpdate')
  end
end })

vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })
local TS = require("nvim-treesitter")

-- 靜態註冊語言別名 (例如將 zsh 指向 bash 的 parser)
vim.treesitter.language.register("bash", "zsh")

-- 定義預先確保安裝的語言清單
local ensure_install = { "lua", "python", "cpp", "c", "scheme", "latex", "bash", "html" }

-- 初始化時先批量安裝基礎語言 (全域)
TS.install(ensure_install)

--- 啟動指定 Buffer 的 Tree-sitter
---@param buf integer
---@param lang string
local function start_treesitter(buf, lang)
  if not vim.treesitter.language.add(lang) then return end

  -- 語法高亮
  vim.treesitter.start(buf, lang)

  -- 折疊設定 (可依需求取消註釋)
  -- vim.wo.foldmethod = "expr"
  -- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

  -- 縮排設定 (可依需求取消註釋)
  -- vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end

--- 檢查與非同步自動下載 Parser
---@param buf integer
---@param lang string
local function ensure_parser(buf, lang)
  if vim.tbl_contains(TS.get_installed("parsers"), lang) then
    start_treesitter(buf, lang)
    return
  end

  TS.install(lang):await(function()
    if vim.api.nvim_buf_is_valid(buf) then
      start_treesitter(buf, lang)
    end
  end)
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = "*",
  group = vim.api.nvim_create_augroup("ts_auto_install", { clear = true }),
  callback = function(event)
    local buf = event.buf
    local ft = event.match

    -- 將 FileType 對應到 Tree-sitter 語言名稱
    local lang = vim.treesitter.language.get_lang(ft) or ft
    if not lang then return end

    -- 檢查是否為 nvim-treesitter 支持的合法語言 parser
    if not vim.tbl_contains(TS.get_available(), lang) then return end

    ensure_parser(buf, lang)
  end,
})



-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>bw", function()
  vim.cmd("w")       -- 儲存檔案
  vim.cmd("bdelete") -- 關閉目前 buffer，但保留分割視窗
end, { desc = "保存並關閉 buffer" })

vim.keymap.set("n", "<leader>t",
  function() require("snacks").terminal(nil, { win = { position = "right" } }) end,
  { desc = "Terminal 右側分割" })

-- Alt+j：在上方插入一行
vim.keymap.set("n", "<A-j>", "O<Esc>", {
  desc = "Insert blank line above",
  silent = true
})

-- Alt+k：刪除上方空白行（不會刪到非空白內容）
vim.keymap.set("n", "<A-k>", function()
  local curr_line = vim.fn.line(".")
  while curr_line > 1 do
    local line_above = vim.fn.getline(curr_line - 1)
    if line_above:match("^%s*$") then
      vim.fn.setline(curr_line - 1, "")
      vim.cmd((curr_line - 1) .. "delete _") -- 使用黑洞寄存器
      curr_line = curr_line - 1
    else
      break
    end
  end
end, { desc = "Delete blank lines above", silent = true })

vim.keymap.set("i", "<C-h>", "<Left>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-j>", "<Down>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-k>", "<Up>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-l>", "<Right>", { noremap = true, silent = true })




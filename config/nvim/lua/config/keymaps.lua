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


-- smear-cursor.lua
if vim.fn.has("wsl") == 1 then
  vim.pack.add({ 'https://github.com/sphamba/smear-cursor.nvim' })
  require('smear_cursor').setup({})
end

-- auto-save
vim.api.nvim_create_autocmd({ 'InsertLeave', 'TextChanged' }, { once = true, callback = function()
  vim.cmd("silent! write")
  vim.pack.add({ 'https://github.com/pocco81/auto-save.nvim' })
  require('auto-save').setup()
end })


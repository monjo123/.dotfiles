-- auto-save
vim.api.nvim_create_autocmd({ 'InsertLeave', 'TextChanged' }, { once = true, callback = function()
  local file_path = vim.fn.expand("<afile>:p:h")
  if vim.fn.isdirectory(file_path) == 0 then
    vim.fn.mkdir(file_path, "p")
  end
  vim.cmd("silent! write")
  vim.pack.add({ 'https://github.com/pocco81/auto-save.nvim' })
  require('auto-save').setup()
end })


-- mason.lua
vim.api.nvim_create_user_command('Mason', function()
  if package.loaded["mason"] == nil then
    vim.api.nvim_del_user_command('Mason')
    vim.pack.add({ 'https://github.com/williamboman/mason.nvim' })
    require("mason").setup()
    vim.schedule(function()
      vim.cmd('Mason')
    end)
  end
end, {})


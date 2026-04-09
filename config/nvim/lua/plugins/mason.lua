-- mason.lua
vim.api.nvim_create_user_command('Mason', function()
    vim.pack.add({ 'https://github.com/williamboman/mason.nvim' })
    require("mason").setup()
    vim.api.nvim_del_user_command('Mason')
    vim.cmd('Mason')
end, {})


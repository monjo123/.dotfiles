-- neogit
vim.api.nvim_create_user_command('Neogit', function()
  if package.loaded["neogit"] == nil then
    vim.api.nvim_del_user_command('Neogit')
    vim.pack.add({
      'https://github.com/neogitorg/neogit',
      'https://github.com/nvim-lua/plenary.nvim',
      'https://github.com/sindrets/diffview.nvim',
      'https://github.com/ibhagwan/fzf-lua'
    })
    vim.schedule(function()
      vim.cmd('Neogit')
    end)
  end
end, {})

vim.keymap.set('n', '<leader>g', "<cmd>Neogit<cr>")

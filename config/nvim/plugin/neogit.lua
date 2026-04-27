-- neogit
vim.pack.add({
  'https://github.com/neogitorg/neogit',
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/sindrets/diffview.nvim',
  'https://github.com/ibhagwan/fzf-lua'
})

vim.keymap.set('n', '<leader>g', "<cmd>Neogit<cr>")

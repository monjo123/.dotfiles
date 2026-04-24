-- flash.lua
vim.pack.add({ 'https://github.com/folke/flash.nvim' })
require("flash").setup()

vim.keymap.set({ 'n', 'x', 'o' }, '<leader>s', function() require("flash").jump() end, { silent = true })
vim.keymap.set({ 'n', 'x', 'o' }, 'S', function() require("flash").treesitter() end, { silent = true })
vim.keymap.set({ 'n', 'x', 'o' }, 'R', function() require("flash").treesitter_search() end, { silent = true })

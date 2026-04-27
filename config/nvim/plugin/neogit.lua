-- neogit
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "NeogitStatus",
  callback = function()
    vim.keymap.set("n", "<CR>", function()
      vim.g.neogit_mode = 0
      return "<CR>"
    end, { buffer = true, expr = true, remap = true })
  end,
})

vim.pack.add({
  'https://github.com/neogitorg/neogit',
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/sindrets/diffview.nvim',
  'https://github.com/ibhagwan/fzf-lua'
})

vim.keymap.set('n', '<leader>g', "<cmd>Neogit<cr>")

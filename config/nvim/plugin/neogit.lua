-- neogit
vim.api.nvim_create_autocmd("BufUnload", {
  group = vim.api.nvim_create_augroup("NeogitAutoExit", { clear = true }),
  pattern = "NeogitStatus",
  callback = function()
    if vim.g.neogit_mode == 1 then
      vim.cmd("quitall")
    end
  end,
})

vim.pack.add({
  'https://github.com/neogitorg/neogit',
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/sindrets/diffview.nvim',
  'https://github.com/ibhagwan/fzf-lua'
})

vim.keymap.set('n', '<leader>g', "<cmd>Neogit<cr>")

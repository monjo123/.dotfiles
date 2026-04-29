vim.pack.add({ 'https://github.com/brenoprata10/nvim-highlight-colors' })
vim.opt.termguicolors = true
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.schedule(function()
      require('nvim-highlight-colors').setup({})
    end)
  end,
})

vim.api.nvim_create_autocmd("FileType", { 
  pattern = "scheme",
  callback = function()
    vim.pack.add({ 'https://github.com/gpanders/nvim-parinfer' })
  end,
})

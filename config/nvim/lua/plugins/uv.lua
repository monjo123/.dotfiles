-- uv
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.pack.add({ 'http://github.com/benomahony/uv.nvim' })
    require('uv').setup({
      picker_integration = true,
    })
  end,
})

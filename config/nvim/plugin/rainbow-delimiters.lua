-- rainbow-delimiters.lua
vim.api.nvim_create_autocmd({"BufReadPost", "BufNewFile"}, {
  callback = function()
    vim.pack.add({ "http://github.com/HiPhish/rainbow-delimiters.nvim" })
  end,
})


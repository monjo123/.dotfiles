-- nvim-surround.lua
vim.api.nvim_create_autocmd({"BufReadPost", "BufNewFile"}, {
  callback = function()
    vim.pack.add({{
      src = "https://github.com/kylechui/nvim-surround",
      version = vim.version.range("4.x"), -- Use for stability; omit to use `main` branch for the latest features
    }})
  end,
})



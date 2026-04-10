-- lualine.lua
vim.api.nvim_create_autocmd("UIEnter", {
    once = true,
    callback = function()
      vim.pack.add({
        'https://github.com/nvim-lualine/lualine.nvim',
        'https://github.com/nvim-tree/nvim-web-devicons',
      })
      require("lualine").setup()
    end,
})


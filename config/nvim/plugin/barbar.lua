-- barbar
vim.api.nvim_create_autocmd('BufAdd', { once = true, callback = function()
  vim.pack.add({
    'https://github.com/nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
    'https://github.com/romgrk/barbar.nvim',
    'https://github.com/lewis6991/gitsigns.nvim', -- OPTIONAL: for git status
  })
  require("barbar").setup({
    -- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
    auto_hide = 1,
    animation = false,
    -- insert_at_start = true,
    -- …etc.
  })
  vim.keymap.set('n', '<leader>b', '<Cmd>BufferPick<CR>')
end })

vim.keymap.set("n", "<tab>", ":BufferNext<CR>", { silent = true, desc = "Next buffer" })
vim.keymap.set("n", "<S-tab>", ":BufferPrevious<CR>", { silent = true, desc = "Previous buffer" })

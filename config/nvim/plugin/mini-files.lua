-- mini-files
vim.pack.add({{ src = 'https://github.com/nvim-mini/mini.files', version = 'stable' }})
require("mini.files").setup({
  options = {
    use_as_default_explorer = true,
  },
  windows = {
    preview = true,
    width_preview = 50,
  },
  mappings = {
    synchronize = '<CR>'
  },
})
vim.keymap.set('n', '<leader>e', function()
  MiniFiles.open(vim.api.nvim_buf_get_name(0))
end)


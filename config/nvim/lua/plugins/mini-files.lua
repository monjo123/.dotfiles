return {
  "echasnovski/mini.files",
  version = '*',
  opts = {
    options = {
      use_as_default_explorer = true,
    },
    windows = {
      preview = true,
      width_preview = 30,
    },
    mappings = {
      synchronize = '<CR>'
    },
  },
  config = function(_, opts)
    require("mini.files").setup(opts)
    vim.keymap.set('n', '<leader>e', '<cmd>lua MiniFiles.open()<CR>')
  end,
}

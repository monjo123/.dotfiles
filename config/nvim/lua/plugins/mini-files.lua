return {
  "echasnovski/mini.files",
  version = '*',
  opts = {
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
  },
  config = function(_, opts)
    require("mini.files").setup(opts)
    vim.keymap.set('n', '<leader>e', function()
      MiniFiles.open(vim.api.nvim_buf_get_name(0))
    end)
  end,
}

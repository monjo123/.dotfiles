return {
  'romgrk/barbar.nvim',
  dependencies = {
    'lewis6991/gitsigns.nvim', -- OPTIONAL: for git status
    'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
  },
  opts = {
    -- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
    auto_hide = 1,
    animation = false,
    -- insert_at_start = true,
    -- …etc.
  },
  config = function(_, opts)
    require("barbar").setup(opts)
    vim.keymap.set('n', '<leader>b', '<Cmd>BufferPick<CR>')
  end,
}

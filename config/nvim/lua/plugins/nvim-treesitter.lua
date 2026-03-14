return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    require("nvim-treesitter.config").setup({
      ensure_installed = {"vim", "lua", "c", "python", "cpp"},
      auto_install = true,
      highlight = {
        enable = true
      },
      indent = {
        enable = true
      }
    })
  end,
}

return {
  {
    "vague-theme/vague.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other plugins
    opts = {
      transparent = true,
    },
    config = function(_, opts)
      require("vague").setup(opts)
      vim.cmd("colorscheme vague")
    end
  },
  {
    "HiPhish/rainbow-delimiters.nvim",
  },
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    opts = {
      auto_install = true,
      highlight = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)
    end,
  }
}

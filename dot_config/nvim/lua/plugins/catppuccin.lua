-- 在 ~/.config/nvim/lua/plugins/catppuccin.lua
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,         -- 延遲載入，除非你希望開啟時就初始化就放 lazy = false
    priority = 1000,     -- 確保在預設 colorscheme 之前先載入
    opts = {
      flavour = "mocha",
      transparent_background = true,
      dim_inactive = {
        enabled = false,
        shade = "dark",
        percentage = 0.15,
      },
      integrations = {
        cmp = true,
        gitsigns = true,
        telescope = true,
        treesitter = true,
        -- ...依需求開啟其他 Integrations
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}

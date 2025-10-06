-- 文件路徑: lua/plugins/rainbow-delimiters.lua
return {
  "HiPhish/rainbow-delimiters.nvim",
  config = function()
    local rainbow_delimiters = require("rainbow-delimiters")

    ---@type rainbow_delimiters.config
    vim.g.rainbow_delimiters = {
      strategy = {
        [''] = 'rainbow-delimiters.strategy.global',
        commonlisp = 'rainbow-delimiters.strategy.local',
      },
      query = {
        [''] = 'rainbow-delimiters',
        latex = 'rainbow-blocks',
      },
      highlight = {
        'RainbowDelimiterMauve',
        'RainbowDelimiterBlue',
        'RainbowDelimiterTeal',
        'RainbowDelimiterYellow',
        'RainbowDelimiterPeach',
        'RainbowDelimiterMaroon',
        'RainbowDelimiterGreen',
      },
    }

    local highlights = {
      RainbowDelimiterMauve  = "#cba6f7", -- 紫色
      RainbowDelimiterBlue   = "#89b4fa", -- 藍色
      RainbowDelimiterTeal   = "#94e2d5", -- 藍綠
      RainbowDelimiterYellow = "#f9e2af", -- 黃色
      RainbowDelimiterPeach  = "#fab387", -- 橙色
      RainbowDelimiterMaroon = "#eba0ac", -- 紅粉
      RainbowDelimiterGreen  = "#a6e3a1", -- 綠色
    }

    for group, color in pairs(highlights) do
      vim.api.nvim_set_hl(0, group, { fg = color })
    end
  end,
}


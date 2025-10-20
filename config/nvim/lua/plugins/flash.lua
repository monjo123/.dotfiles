return {
  "folke/flash.nvim",
  event = "VeryLazy",
  ---@type Flash.Config
  opt = {},
  -- stylua: ignore
  keys = {
    { "<leader>s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "<leader>S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
  },
}

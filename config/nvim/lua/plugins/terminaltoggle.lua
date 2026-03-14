return {
  'akinsho/toggleterm.nvim',
  version = "*",
  opts = {
    start_in_insert = true,
  },
  keys = {
    {"<leader>t", mode = { "n" }, "<cmd>ToggleTerm direction=horizontal<CR>" },
    {"<leader>T", mode = { "n" }, "<cmd>ToggleTerm direction=float<CR>" },
  },
  config = function(_, opts)
    require("toggleterm").setup(opts)
  end
}

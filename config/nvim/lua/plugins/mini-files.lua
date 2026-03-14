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
  keys = {
    {"<leader>e", mode = { "n" }, "<cmd>lua MiniFiles.open()<CR>" },
  },
  config = function(_, opts)
    require("mini.files").setup(opts)
  end,
}

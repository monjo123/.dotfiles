return {
  "anuvyklack/windows.nvim",
  dependencies = { "anuvyklack/middleclass" },
  config = function()
    require("windows").setup()
    vim.keymap.set('n', '<A-f>', '<Cmd>WindowsMaximize<CR>', { desc = "Toggle window zoom" })
  end
}

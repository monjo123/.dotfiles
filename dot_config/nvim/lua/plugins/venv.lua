return {
  "linux-cultist/venv-selector.nvim",
  cmd = "VenvSelect",
  opts = {
    search = true,
    search_venv_managers = false,
    name = ".venv",
  },
  keys = {
    { "<leader>cv", "<cmd>VenvSelect<CR>", desc = "選擇 Python 虛擬環境" },
  },
}


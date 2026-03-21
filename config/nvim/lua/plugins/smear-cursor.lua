return {
  "sphamba/smear-cursor.nvim",
  cond = function()
    return vim.fn.has("wsl")
  end,
  opts = {

  },
}

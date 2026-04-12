-- lazygit.lua
vim.keymap.set("n", "<leader>g", function()
  if not package.loaded["lazygit"] then
    vim.pack.add({
      "https://github.com/kdheepak/lazygit.nvim",
      "https://github.com/nvim-lua/plenary.nvim",
    })
  end

  require("lazygit").lazygit()
end, { silent = true, desc = "LazyGit" })



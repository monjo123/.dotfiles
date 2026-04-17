-- leetcode.lua
if vim.fn.argv(0) == "leetcode.nvim" then
  vim.pack.add({
    "https://github.com/kawre/leetcode.nvim",
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/MunifTanjim/nui.nvim",
    "https://github.com/ibhagwan/fzf-lua",
    "https://github.com/nvim-tree/nvim-web-devicons",
  })

  require("leetcode").setup({
    picker = { provider = fzf },

    injector = {
      ["python3"] = {
        imports = function(default_imports)
          vim.list_extend(default_imports, { "from .leetcode import *" })
          return default_imports
        end,
        after = { "def test():", "    print('test')" },
      },
      ["cpp"] = {
        imports = function()
          -- return a different list to omit default imports
          return { "#include <bits/stdc++.h>", "using namespace std;" }
        end,
        after = "int main() {}",
      },
    },

    storage = {
      home = "~/Projects/leetcode",
      cache = vim.fn.stdpath("cache") .. "/leetcode",
    },
  })
  vim.cmd('Leet')
end





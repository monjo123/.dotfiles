return {
  "kawre/leetcode.nvim",
  dependencies = {
    -- include a picker of your choice, see picker section for more details
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  cmd = "Leet",
  lazy = vim.fn.argv(0) ~= "leetcode.nvim",

  opts = {
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
      home = "/home/ocean/ContestProgramming/leetcode",
      cache = vim.fn.stdpath("cache") .. "/leetcode",
    },

    image_support = true,
  },
}

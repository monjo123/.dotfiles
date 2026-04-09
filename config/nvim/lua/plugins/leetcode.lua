-- leetcode.lua
if vim.fn.argv(0) == "leetcode.nvim" then
  vim.pack.add({
    "https://github.com/kawre/leetcode.nvim",
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/MunifTanjim/nui.nvim",
    "https://github.com/3rd/image.nvim",
  })

  require("image").setup({
    processor = "magick_cli",
  })
  require("leetcode").setup({
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
      home = "~/leetcode",
      cache = vim.fn.stdpath("cache") .. "/leetcode",
    },
    image_support = true,
  })
  vim.cmd('Leet')
end



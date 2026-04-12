-- nvim-treesitter-textobjects
vim.pack.add({{ src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" }})
vim.g.no_plugin_maps = true
require("nvim-treesitter-textobjects").setup {
  select = {
    lookahead = true,
  }
}

vim.keymap.set({ "x", "o" }, "am", function()
  require "nvim-treesitter-textobjects.select".select_textobject("@function.outer", "textobjects")
end, { silent = true })
vim.keymap.set({ "x", "o" }, "im", function()
  require "nvim-treesitter-textobjects.select".select_textobject("@function.inner", "textobjects")
end, { silent = true })
vim.keymap.set({ "x", "o" }, "ac", function()
  require "nvim-treesitter-textobjects.select".select_textobject("@class.outer", "textobjects")
end, { silent = true })
vim.keymap.set({ "x", "o" }, "ic", function()
  require "nvim-treesitter-textobjects.select".select_textobject("@class.inner", "textobjects")
end, { silent = true })
vim.keymap.set({ "x", "o" }, "al", function()
  require "nvim-treesitter-textobjects.select".select_textobject("@loop.outer", "textobjects")
end, { silent = true })
vim.keymap.set({ "x", "o" }, "il", function()
  require "nvim-treesitter-textobjects.select".select_textobject("@loop.inner", "textobjects")
end, { silent = true })
vim.keymap.set({ "x", "o" }, "as", function()
  require "nvim-treesitter-textobjects.select".select_textobject("@local.scope", "locals")
end, { silent = true })

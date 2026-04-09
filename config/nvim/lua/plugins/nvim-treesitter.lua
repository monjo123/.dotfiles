-- nvim-treesitter.lua
vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })
require("nvim-treesitter").install({ "lua", "python", "cpp", "c", "scheme", "latex", "bash", "html" })
vim.treesitter.language.register("bash", "zsh")
vim.api.nvim_create_autocmd("FileType", {
  pattern = { '<filetype>' },
  callback = function(args)
    local bufnr = args.buf

    pcall(vim.treesitter.start, bufnr)

    vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})


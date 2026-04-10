-- nvim-treesitter.lua
vim.api.nvim_create_autocmd({"BufReadPost", "BufNewFile"}, {
  callback = function()
    vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })
    local ensure_install = { "lua", "python", "cpp", "c", "scheme", "latex", "bash", "html" };
    require("nvim-treesitter").install(ensure_install)
    vim.treesitter.language.register("bash", "zsh")
    vim.api.nvim_create_autocmd('FileType', {
      pattern = ensure_install,
      callback = function() 
        vim.treesitter.start() 
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
})


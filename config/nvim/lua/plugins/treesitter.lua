-- plugins/treesitter.lua
return {
    "nvim-treesitter/nvim-treesitter", 
    build = ":TSUpdate",
    opts = {
        ensure_installed = { "lua", "vim" },
    },
    config = function()
        local configs = require("nvim-treesitter.configs")

        configs.setup({
            highlight = { enable = true },
            auto_install = true
        })
    end,
}

-- plugins/treesitter.lua
return {
    "nvim-treesitter/nvim-treesitter", 
    build = ":TSUpdate",
    opts = {
        auto_install = true
    }
}


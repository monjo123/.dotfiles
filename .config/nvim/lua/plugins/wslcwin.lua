return {
    {
        "kenis1108/wslcwin.nvim",
        event = "VeryLazy",
        config = function()
            require("wslcwin").setup()
        end,
        -- 仅在 WSL 环境中启用
        cond = function()
            return vim.fn.getenv("WSL_DISTRO_NAME") ~= vim.NIL
        end,
    }
}


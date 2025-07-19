return {
    {
        "kenis1108/wslcwin.nvim",
        event = "VeryLazy",
        config = function()
            require("wslcwin").setup()
        end,
        -- Only enable in WSL environment
        cond = function()
            return vim.fn.getenv("WSL_DISTRO_NAME") ~= vim.NIL
        end
    }
}

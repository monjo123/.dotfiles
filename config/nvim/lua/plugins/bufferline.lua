return {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',

    opts = {
        options = {
            mode = "buffers",
            custom_filter = function(bufnr)
                return vim.api.nvim_buf_get_option(bufnr, 'buftype') ~= 'terminal'
            end,
        }
    },

    config = function(_, opts)
        vim.opt.termguicolors = true,
        require("bufferline").setup(opts)
    end,
}

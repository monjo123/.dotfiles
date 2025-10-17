-- Plugin declaration for lazy.nvim
return {
    {
        'akinsho/bufferline.nvim',
        version = "*",
        dependencies = 'nvim-tree/nvim-web-devicons',
        config = function()
            -- Enable true colors
            vim.opt.termguicolors = true
            -- Setup bufferline
            require("bufferline").setup {
              options = {
                -- Sort buffers to place terminals last, others by buffer ID (default)
                sort_by = function(buffer_a, buffer_b)
                    local buftype_a = vim.bo[buffer_a.id].buftype or ''
                    local buftype_b = vim.bo[buffer_b.id].buftype or ''
                    -- If buffer_a is terminal and buffer_b is not, place buffer_a last
                    if buftype_a == 'terminal' and buftype_b ~= 'terminal' then
                        return false
                    end
                    -- If buffer_b is terminal and buffer_a is not, place buffer_b last
                    if buftype_a ~= 'terminal' and buftype_b == 'terminal' then
                        return true
                    end
                    -- For non-terminal vs non-terminal or terminal vs terminal, sort by buffer ID
                    return buffer_a.id < buffer_b.id
                end,
                separator_style = { '' },
                always_show_bufferline = false,
                indicator = {
                  style = 'none',
                },
                diagnostics = "nvim_lsp",
                diagnostics_indicator = function(count, level)
                        local icon = level:match("error") and " " or " "
                        return " " .. icon .. count
                end
              }
            }
        end
    }
}

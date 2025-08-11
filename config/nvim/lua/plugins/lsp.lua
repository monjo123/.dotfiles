return {
    {
        "mason-org/mason.nvim",
        opts = {}
    },
    {
      'neovim/nvim-lspconfig',
      dependencies = { 'saghen/blink.cmp' },

      -- example calling setup directly for each LSP
      config = function()
        vim.diagnostic.config({
          signs = false,
          virtual_text = { spacing = 2, prefix = "●" },
        })
        local capabilities = require('blink.cmp').get_lsp_capabilities()
        local lspconfig = require('lspconfig')

        lspconfig['lua_ls'].setup({ capabilities = capabilities })

        vim.keymap.set("n", "R", vim.lsp.buf.rename, { desc = "LSP: Rename symbol", noremap = true, silent = true })
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "LSP: Go to definition" })
        vim.keymap.set("n", "go", vim.lsp.buf.references, { desc = "LSP: Go to references"})
        vim.keymap.set("n", "<leader>d",vim.lsp.buf.hover, { desc = "LSP: Show document" }) 
        vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, { desc = "LSP: Go to type_definition" }) 


      end
    },
}

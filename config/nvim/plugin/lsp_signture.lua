-- lsp_signture.lua
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function()
    vim.pack.add({ 'https://github.com/ray-x/lsp_signature.nvim' })
    require("lsp_signature").setup()
  end
})


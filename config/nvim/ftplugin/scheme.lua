vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = "*.scm",
  command = "set filetype=scheme",
})

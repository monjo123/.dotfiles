vim.api.nvim_create_autocmd('PackChanged', { callback = function(ev)
  local name, kind = ev.data.spec.name, ev.data.kind
  if name == 'parinfer-rust' and (kind == 'install' or kind == 'update') then
    if not ev.data.active then vim.cmd.packadd('parinfer-rust') end
    vim.system({'cargo', 'build', '--release'}, { cwd = ev.data.path }):wait()
  end
end })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "scheme",
  callback = function()
    vim.pack.add({ 'https://github.com/eraserhd/parinfer-rust' })
  end,
})

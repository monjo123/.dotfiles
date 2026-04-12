vim.api.nvim_create_autocmd('PackChanged', { callback = function(ev)
  local name, kind = ev.data.spec.name, ev.data.kind
  if name == 'parinfer-rust' and (kind == 'install' or kind == 'update') then
    vim.system({'cargo', 'build', '--release'}, { cwd = ev.data.path }):wait()
  end
end })


vim.api.nvim_create_autocmd("FileType", {
  pattern = "scheme",
  callback = function()
    vim.pack.add({ 'https://github.com/eraserhd/parinfer-rust' })
  end,
})

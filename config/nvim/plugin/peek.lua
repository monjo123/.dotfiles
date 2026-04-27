-- peek
vim.api.nvim_create_autocmd('PackChanged', { callback = function(ev)
  local name, kind = ev.data.spec.name, ev.data.kind
  if name == 'peek.nvim' and (kind == 'install' or kind == 'update') then
    if not ev.data.active then vim.cmd.packadd('peek') end
    vim.system({"deno", "task", "--quiet", "build:fast"}, { cwd = ev.data.path }):wait()
  end
end })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.pack.add({ 'https://github.com/toppair/peek.nvim' })
    require("peek").setup({
      app = 'brave'
    })
    vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
    vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
    vim.keymap.set("n", "<leader>p", function() require("peek").open() end, { silent = true })
  end,
})


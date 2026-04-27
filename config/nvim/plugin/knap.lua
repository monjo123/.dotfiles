-- knap
vim.api.nvim_create_autocmd("FileType", {
  pattern = { 'markdown', 'tex' },
  callback = function()
    vim.pack.add({ 'https://github.com/frabjous/knap' })
    vim.keymap.set( 'n' ,'<leader>p', function() require("knap").toggle_autopreviewing() end)
  end,
})

vim.g.knap_settings = {
    htmltohtml = [[A=%outputfile% ; B="${A%.html}-preview.html" ; sed 's/<\/head>/<meta http-equiv="refresh" content="1" ><\/head>/' "$A" > "$B"]],
    htmltohtmlviewerlaunch = [[A=%outputfile% ; B="${A%.html}-preview.html" ; brave "$B"]],
    htmltohtmlviewerrefresh = "none",

    mdtohtml = [[A=%outputfile% ; B="${A%.html}-preview.html" ; pandoc --standalone %docroot% -o "$A" && sed 's/<\/head>/<meta http-equiv="refresh" content="1" ><\/head>/' "$A" > "$B"]],
    mdtohtmlviewerlaunch = [[A=%outputfile% ; brave "${A%.html}-preview.html"]],
    mdtohtmlviewerrefresh = "none",
}

vim.g.knap_settings = {
    ["textopdfviewerlaunch"] = [[brave %outputfile%]],
    ["textopdfviewerrefresh"] = "none",
    ["textopdfforwardjump"] = [[brave %outputfile%]]
}

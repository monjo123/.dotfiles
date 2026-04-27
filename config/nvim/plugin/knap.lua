-- knap
vim.api.nvim_create_autocmd("FileType", {
  pattern = { 'markdown', 'tex', 'html' },
  callback = function()
    vim.pack.add({ 'https://github.com/frabjous/knap' })
    vim.keymap.set( 'n' ,'<leader>p', function() require("knap").toggle_autopreviewing() end)
  end,
})

local css_path = vim.fn.expand("~/.config/nvim/static/github-markdown-dark.css")

vim.g.knap_settings = {
    ["htmltohtmlviewerlaunch"] = [[live-server --quiet --browser=brave --open=%outputfile% --watch=%outputfile% --wait=800]],
    ["htmltohtmlviewerrefresh"] = "none",

    ["mdtohtml"] = [[pandoc --standalone --embed-resources ]] ..
                   [[--css="]] .. css_path .. [[" ]] ..
                   [[--wrap=none ]] ..
                   [[--variable=include-before:'<article class="markdown-body">' ]] ..
                   [[--variable=include-after:'</article>' ]] ..
                   [[%docroot% -o /tmp/preview.html]],

    ["mdtohtmlviewerlaunch"] = [[live-server /tmp --quiet --browser=brave --open=preview.html --watch=preview.html --wait=800]],
    ["mdtohtmlviewerrefresh"] = "none",

    ["textopdfviewerlaunch"] = [[evince %outputfile%]],
    ["textopdfviewerrefresh"] = "none",
    ["textopdfforwardjump"] = [[evince %outputfile%]]
}


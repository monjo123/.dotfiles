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
    ["htmltohtml"] = [[A=/tmp/test ; B="${A%.html}-preview.html" ; sed 's/<\/head>/<meta http-equiv="refresh" content="1" ><\/head>/' "$A" > "$B"]],
    ["htmltohtmlviewerlaunch"] = [[A=/tmp/test ; B="${A%.html}-preview.html" ; brave "$B"]],
    ["htmltohtmlviewerrefresh"] = "none",

    ["mdtohtml"] = [[A="/tmp/test" ; B="${A%.html}-preview.html" ; ]] ..
                   [[pandoc --standalone ]] ..
                   [[--css="]] .. css_path .. [[" ]] ..
                   [[--variable=header-includes:'<style>body{background-color:#0d1117;margin:0;padding:45px;}</style>' ]] ..
                   [[--variable=include-before:'<article class="markdown-body">' ]] ..
                   [[--variable=include-after:'</article>' ]] ..
                   [[%docroot% -o "$A" && ]] ..
                   [[sed 's/<\/head>/<meta http-equiv="refresh" content="1" ><\/head>/' "$A" > "$B"]],
    ["mdtohtmlviewerlaunch"] = [[A=/tmp/test ; brave "${A%.html}-preview.html"]],
    ["mdtohtmlviewerrefresh"] = "none",

    ["textopdfviewerlaunch"] = [[brave %outputfile%]],
    ["textopdfviewerrefresh"] = "none",
    ["textopdfforwardjump"] = [[brave %outputfile%]]
}


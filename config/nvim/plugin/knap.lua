vim.api.nvim_create_autocmd("FileType", {


  pattern = { "markdown", "tex", "html" },

  callback = function()
    vim.pack.add({
      "https://github.com/frabjous/knap",
    })

    vim.keymap.set("n", "<leader>p", function()
      require("knap").process_once()
    end)
  end,
})


local css_path = vim.fn.expand(
  "~/.config/nvim/static/github-markdown-dark.css"
)


local gknapsettings = {
  ---------------------------------------------------------------------------
  -- LaTeX
  ---------------------------------------------------------------------------

  texoutputext = "pdf",

  textopdf = [[
    sh -c 'xelatex -interaction=batchmode -halt-on-error -synctex=1 "$1"; status=$?; if [ "$status" -eq 0 ]; then rm -f *.aux *.out *.synctex.gz *.toc *.fdb_latexmk *.fls *.log; fi; exit "$status"' sh %docroot%
  ]],


  ---------------------------------------------------------------------------
  -- PDF Viewer
  ---------------------------------------------------------------------------

  textopdfviewerlaunch = "open -a Skim %outputfile%",
  textopdfviewerrefresh = "none",
  textopdfforwardjump = "open -a Skim %outputfile%",


  ---------------------------------------------------------------------------
  -- Error message
  ---------------------------------------------------------------------------

  textopdfshorterror = [[
    A=%outputfile%
    LOGFILE="${A%.pdf}.log"

    if [ -f "$LOGFILE" ]; then
      if grep -q '^!' "$LOGFILE"; then
        grep -A 6 -m 1 '^!' "$LOGFILE"
      else
        tail -n 30 "$LOGFILE"
      fi
    else
      echo "LaTeX compilation failed, but no .log file was found."
    fi
  ]],


  ---------------------------------------------------------------------------
  -- KNAP delay
  ---------------------------------------------------------------------------

  delay = 250,
}


vim.g.knap_settings = gknapsettings

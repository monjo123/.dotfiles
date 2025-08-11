return {
  "lewis6991/gitsigns.nvim",
  event = "BufReadPre",  
  config = function()
    require("gitsigns").setup({
      signs = {
        add          = { text = "│", hl = "GitSignsAdd" },
        change       = { text = "│", hl = "GitSignsChange" },
        delete       = { text = "_", hl = "GitSignsDelete" },
        topdelete    = { text = "‾", hl = "GitSignsDelete" },
        changedelete = { text = "~", hl = "GitSignsChange" },
        untracked    = { text = "┆", hl = "GitSignsAdd" },
      },
      signcolumn = true,
      numhl      = false,
      linehl     = true,
      watch_gitdir = { follow_files = true },
      current_line_blame = false,
    })
  end,
}

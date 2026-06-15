vim.opt.conceallevel = 1
vim.api.nvim_create_autocmd("FileType", {
  pattern = { 'markdown' },
  callback = function()
    vim.pack.add({ 'https://github.com/obsidian-nvim/obsidian.nvim' })
    require("obsidian").setup {
      workspaces = {
        {
          name = "Obsidian",
          path = "~/Obsidian", 
        },
      },
      legacy_commands = false,
      picker = {
        -- name = "snacks.picker", -- use snacks picker
        -- name = "telescope.nvim",   -- or telescope
        name = "fzf-lua",     -- or fzf-lua
        -- name = "mini.pick",   -- or mini.pick
      },
    }
  end,
})


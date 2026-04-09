-- fzf.lua
local function fzf_lua()
  if package.loaded["fzf-lua"] == nil then
    vim.pack.add({
      "https://github.com/ibhagwan/fzf-lua",
      "https://github.com/nvim-tree/nvim-web-devicons",
    })

    require("fzf-lua").setup({
      keymap = {
        fzf = {
          ["tab"] = "down",
          ["shift-tab"] = "up",
        },
      },
    })

    require("fzf-lua").register_ui_select()
  end

  return require("fzf-lua")
end

vim.keymap.set("n", "<leader>ff", function() fzf_lua().files() end, { desc = "find files" })
vim.keymap.set("n", "<leader>fg", function() fzf_lua().grep() end, { desc = "grep" })
vim.keymap.set("n", "<leader>fh", function() fzf_lua().oldfiles() end, { desc = "history" })
vim.keymap.set("n", "<leader>fd", function() fzf_lua().zoxide() end, { desc = "zoxide" })
vim.keymap.set("n", "<leader>t", function() fzf_lua().treesitter() end, { desc = "treesitter" })
vim.keymap.set("n", "gw", function() fzf_lua().diagnostics_workspace() end, { desc = "diagnostics workspace" })
vim.keymap.set("n", "gr", function() fzf_lua().lsp_references() end, { desc = "lsp references" })
vim.keymap.set("n", "gd", function() fzf_lua().lsp_definitions() end, { desc = "lsp definitions" })
vim.keymap.set("n", "gD", function() fzf_lua().lsp_declarations() end, { desc = "lsp declarations" })
vim.keymap.set("n", "gt", function() fzf_lua().lsp_typedefs() end, { desc = "lsp typedefs" })
vim.keymap.set("n", "gi", function() fzf_lua().lsp_implementations() end, { desc = "lsp implementations" })
vim.keymap.set("n", "<leader>a", function() fzf_lua().lsp_code_actions() end, { desc = "code actions" })



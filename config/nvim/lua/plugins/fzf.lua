return {
  "ibhagwan/fzf-lua",
  -- optional for icon support
  dependencies = { "nvim-tree/nvim-web-devicons" },
  -- or if using mini.icons/mini.nvim
  -- dependencies = { "nvim-mini/mini.icons" },
  ---@module "fzf-lua"
  ---@diagnostic disable: missing-fields
  opts = {
    keymap = {
      fzf = {
        ["tab"] = "down",
        ["shift-tab"] = "up",
      }
    }
  },
  ---@diagnostic enable: missing-fields
  keys = {
    { "<leader>ff", "<cmd>FzfLua files<CR>" },
    { "<leader>fg", "<cmd>FzfLua grep<CR>" },
    { "<leader>fh", "<cmd>FzfLua history<CR>" },
    { "<leader>ft", "<cmd>FzfLua treesitter<CR>" },
    { "<leader>fd", "<cmd>FzfLua zoxide<CR>" },
    { "gw", "<cmd>FzfLua diagnostics_workspace<CR>" },
    { "gr", "<cmd>FzfLua lsp_references<CR>" },
    { "gd", "<cmd>FzfLua lsp_definitions<CR>" },
    { "gD", "<cmd>FzfLua lsp_declarations<CR>" },
    { "gt", "<cmd>FzfLua lsp_typedefs<CR>" },
    { "gi", "<cmd>FzfLua lsp_implementations<CR>" },
    { "<leader>a", "<cmd>FzfLua lsp_code_actions<CR>" },


  },

}

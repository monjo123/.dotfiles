return {
  {
    "bkad/CamelCaseMotion",
    event = "VeryLazy", 
    config = function()
      vim.keymap.set('n', 'w', '<Plug>CamelCaseMotion_w', { silent = true, desc = 'Move to next camelCase/snake_case word' })
      vim.keymap.set('n', 'b', '<Plug>CamelCaseMotion_b', { silent = true, desc = 'Move to previous camelCase/snake_case word' })
      vim.keymap.set('n', 'e', '<Plug>CamelCaseMotion_e', { silent = true, desc = 'Move to end of camelCase/snake_case word' })
      vim.keymap.set('n', 'ge', '<Plug>CamelCaseMotion_ge', { silent = true, desc = 'Move to end of previous camelCase/snake_case word' })

      vim.keymap.set({'v', 'o'}, 'iw', '<Plug>CamelCaseMotion_iw', { silent = true, desc = 'Select inner camelCase/snake_case word' })

      vim.keymap.set({'v', 'o'}, '<leader>w', '<Plug>CamelCaseMotion_w', { silent = true, desc = 'Move to next camelCase/snake_case word' })
      vim.keymap.set({'v', 'o'}, '<leader>b', '<Plug>CamelCaseMotion_b', { silent = true, desc = 'Move to previous camelCase/snake_case word' })
      vim.keymap.set({'v', 'o'}, '<leader>e', '<Plug>CamelCaseMotion_e', { silent = true, desc = 'Move to end of camelCase/snake_case word' })
    end,
  },
}

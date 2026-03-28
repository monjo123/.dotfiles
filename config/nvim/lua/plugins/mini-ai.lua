return {
  'nvim-mini/mini.ai',
  version = '*',
  config = function()
    require('mini.ai').setup({
      -- Table with textobject id as fields, textobject specification as values.
      -- Also use this to disable builtin textobjects. See |MiniAi.config|.
      custom_textobjects = {
        a = require('mini.ai').gen_spec.argument({
          brackets = { '%b<>','%b()', '%b[]', '%b{}' },
          separator = '[,;]+'
        }),
        s = require('mini.ai').gen_spec.argument({
          brackets = { '%b<>', '%b()', '%b[]', '%b{}' },
          separator = '[&|]+'
        }),

        b = false,

        l = require('mini.ai').gen_spec.treesitter({ a = '@loop.outer', i = '@loop.inner' }),
        f = require('mini.ai').gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }),
        c = require('mini.ai').gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }),
      },

      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        -- Main textobject prefixes
        around = 'a',
        inside = 'i',

        -- Next/last variants
        -- NOTE: These override built-in LSP selection mappings on Neovim>=0.12
        -- Map LSP selection manually to use it (see `:h MiniAi.config`)
        around_next = '',
        inside_next = '',
        around_last = '',
        inside_last = '',

        -- Move cursor to corresponding edge of `a` textobject
        goto_left = '',
        goto_right = '',
      },

      -- Number of lines within which textobject is searched
      n_lines = 50,

      -- How to search for object (first inside current line, then inside
      -- neighborhood). One of 'cover', 'cover_or_next', 'cover_or_prev',
      -- 'cover_or_nearest', 'next', 'previous', 'nearest'.
      search_method = 'cover_or_next',

      -- Whether to disable showing non-error feedback
      -- This also affects (purely informational) helper messages shown after
      -- idle time if user input is required.
      silent = false,
    })
  end
}

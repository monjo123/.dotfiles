-- blink-cmp
vim.api.nvim_create_autocmd('InsertEnter', { once = true, callback = function()
  vim.pack.add({
    { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('*') },
    'https://github.com/xzbdmw/colorful-menu.nvim',
    'https://github.com/rafamadriz/friendly-snippets',
  })
  require('colorful-menu').setup()
  require('blink.cmp').setup({
    -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
    -- 'super-tab' for mappings similar to vscode (tab to accept)
    -- 'enter' for enter to accept
    -- 'none' for no mappings
    --
    -- All presets have the following mappings:
    -- C-space: Open menu or open docs if already open
    -- C-n/C-p or Up/Down: Select next/previous item
    -- C-e: Hide menu
    -- C-k: Toggle signature help (if signature.enabled = true)
    --
    -- See :h blink-cmp-config-keymap for defining your own keymap
    keymap = {
      ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      ['<C-e>'] = { 'hide', 'fallback' },

      ['<Tab>'] = { 
        'select_next',      
        'snippet_forward',
        'fallback'      
      },
      ['<S-Tab>'] = { 
        'select_prev', 
        'snippet_backward', 
        'fallback'         
      }, 

      ['<Up>'] = { 
        'select_next',      
        'snippet_forward',
        'fallback'      
      },
      ['<Down>'] = { 
        'select_prev', 
        'snippet_backward', 
        'fallback'         
      },

      ['<CR>'] = { 'accept', 'fallback' },

      ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
      ['<C-n>'] = { 'select_next', 'fallback_to_mappings' },

      ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
      ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

      ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
    },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'mono'
    },

    -- (Default) Only show the documentation popup when manually triggered
    completion = {
      ghost_text = {
        enabled = true, 
      },
      documentation = {
        auto_show = true
      },
      trigger = {
        show_on_trigger_character = true
      },
      list = {
        selection = {
          preselect = false,
          auto_insert = true
        }
      },
      accept = {
        auto_brackets = {
          enabled = true,
        },
      },
      menu = {
        draw = {
          -- We don't need label_description now because label and label_description are already
          -- combined together in label by colorful-menu.nvim.
          columns = { { "kind_icon" }, { "label", gap = 1 } },
          components = {
            label = {
              text = function(ctx)
                return require("colorful-menu").blink_components_text(ctx)
              end,
              highlight = function(ctx)
                return require("colorful-menu").blink_components_highlight(ctx)
              end,
            },
          },
        },
      },
    },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },

    -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
    -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
    -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
    --
    -- See the fuzzy documentation for more information
    fuzzy = { implementation = "prefer_rust_with_warning" }
  })
end })


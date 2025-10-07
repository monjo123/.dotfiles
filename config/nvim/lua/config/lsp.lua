-- ============================================================================
-- LSP Configuration for Neovim
-- ============================================================================

-- ============================================================================
-- LSP SERVER CONFIGURATIONS
-- ============================================================================

-- Global configuration for ALL servers
vim.lsp.config('*', {
  root_markers = { '.git' },
  capabilities = {
    textDocument = {
      semanticTokens = {
        multilineTokenSupport = true,
      },
    },
  },
})

vim.lsp.enable('lua_ls')
vim.lsp.enable('clangd')

-- ============================================================================
-- GLOBAL SETTINGS
-- ============================================================================

-- Configure diagnostics display
vim.diagnostic.config({
  virtual_text = true,
  signs = false,
  underline = true,
})

-- Show virtual text on CursorHold
vim.api.nvim_create_autocmd('CursorHoldI', {
  buffer = bufnr, -- remove this line if you want it global
  callback = function()
    vim.diagnostic.config({ update_in_insert = true })
  end
})

-- Optional: hide virtual text again when cursor moves
vim.api.nvim_create_autocmd('CursorMovedI', {
  buffer = bufnr,
  callback = function()
    vim.diagnostic.config({ update_in_insert = false })
  end
})

-- ============================================================================
-- DISABLE DEFAULT KEYMAPS (Optional - comment out to keep defaults)
-- ============================================================================

-- Default global keymaps that Nvim creates:
-- gra - code action
-- gri - implementation
-- grn - rename
-- grr - references
-- grt - type definition
-- gO - document symbols
-- CTRL-S (insert mode) - signature help
-- an/in (visual mode) - selection range

-- Uncomment to remove default keymaps:
-- vim.keymap.del('n', 'gra')
-- vim.keymap.del('n', 'gri')
-- vim.keymap.del('n', 'grn')
-- vim.keymap.del('n', 'grr')
-- vim.keymap.del('n', 'grt')
-- vim.keymap.del('n', 'gO')
-- vim.keymap.del('i', '<C-S>')
-- vim.keymap.del('v', 'an')
-- vim.keymap.del('v', 'in')

-- ============================================================================
-- DISABLE BUFFER-LOCAL DEFAULTS ON ATTACH
-- ============================================================================

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp_disable_defaults', { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    -- DISABLE AUTO-COMPLETION (since you use Blink.cmp)
    -- This prevents the default omnifunc from being set
    vim.bo[bufnr].omnifunc = nil

    -- Optional: Disable other defaults
    -- vim.bo[bufnr].formatexpr = nil  -- Disable gq formatting
    -- vim.keymap.del('n', 'K', { buffer = bufnr })  -- Disable K for hover
  end,
})

-- ============================================================================
-- CUSTOM KEYMAPS ON ATTACH
-- ============================================================================

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp_custom_keymaps', { clear = true }),
  callback = function(args)
    -- local bufnr = args.buf
    -- local client = vim.lsp.get_client_by_id(args.data.client_id)
    --
    -- -- Helper function for setting keymaps
    -- local function map(mode, lhs, rhs, desc)
    --   vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = 'LSP: ' .. desc })
    -- end

    -- Navigation
    -- map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
    -- map('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration')
    -- map('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation')
    -- map('n', 'gt', vim.lsp.buf.type_definition, 'Go to type definition')
    -- map('n', 'gr', vim.lsp.buf.references, 'Show references')

    -- Documentation
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'LSP: Hover documentation' })
    -- map('n', '<C-k>', vim.lsp.buf.signature_help, 'Signature help')
    -- map('i', '<C-k>', vim.lsp.buf.signature_help, 'Signature help')

    -- Code actions
    vim.keymap.set({ 'v', 'n' }, '<leader>a', vim.lsp.buf.code_action, { desc = 'LSP: Code action' })
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'LSP: Rename symbol' })

    -- Formatting
    -- if client:supports_method('textDocument/formatting') then
    --   map('n', '<leader>f', function()
    --     vim.lsp.buf.format({ async = false, timeout_ms = 2000 })
    --   end, 'Format buffer')
    -- end

    -- Diagnostics
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'LSP: Previous diagnostic' })
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'LSP: Next diagnostic' })
    -- map('n', '<leader>e', vim.diagnostic.open_float, 'Show diagnostic')
    -- map('n', '<leader>q', vim.diagnostic.setloclist, 'Diagnostics to loclist')

    -- Workspace
    vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, { desc = 'Add workspace folder' })
    map('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, 'Remove workspace folder')
    map('n', '<leader>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, 'List workspace folders')

    -- Symbols
    map('n', '<leader>ds', vim.lsp.buf.document_symbol, 'Document symbols')
    map('n', '<leader>ws', vim.lsp.buf.workspace_symbol, 'Workspace symbols')

    -- Call hierarchy
    if client:supports_method('callHierarchy/incomingCalls') then
      map('n', '<leader>ci', vim.lsp.buf.incoming_calls, 'Incoming calls')
    end
    if client:supports_method('callHierarchy/outgoingCalls') then
      map('n', '<leader>co', vim.lsp.buf.outgoing_calls, 'Outgoing calls')
    end

    -- Type hierarchy
    if client:supports_method('typeHierarchy/subtypes') then
      map('n', '<leader>ts', function()
        vim.lsp.buf.typehierarchy('subtypes')
      end, 'Type subtypes')
    end
    if client:supports_method('typeHierarchy/supertypes') then
      map('n', '<leader>tS', function()
        vim.lsp.buf.typehierarchy('supertypes')
      end, 'Type supertypes')
    end

    -- Code lens
    -- if client:supports_method('textDocument/codeLens') then
    --   map('n', '<leader>cl', vim.lsp.codelens.run, 'Run code lens')
    --   map('n', '<leader>cL', vim.lsp.codelens.refresh, 'Refresh code lens')
    --
    --   -- Auto-refresh code lens
    --   vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
    --     buffer = bufnr,
    --     callback = vim.lsp.codelens.refresh,
    --   })
    -- end

    -- Document highlight
    if client:supports_method('textDocument/documentHighlight') then
      map('n', '<leader>h', vim.lsp.buf.document_highlight, 'Highlight references')
      map('n', '<leader>H', vim.lsp.buf.clear_references, 'Clear highlights')

      -- Optional: Auto-highlight on cursor hold
      -- vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
      --   buffer = bufnr,
      --   callback = vim.lsp.buf.document_highlight,
      -- })
      -- vim.api.nvim_create_autocmd('CursorMoved', {
      --   buffer = bufnr,
      --   callback = vim.lsp.buf.clear_references,
      -- })
    end

    -- Selection range (incremental selection)
    if client:supports_method('textDocument/selectionRange') then
      map('v', '<leader>v', function()
        vim.lsp.buf.selection_range(1) -- Expand
      end, 'Expand selection')
      map('v', '<leader>V', function()
        vim.lsp.buf.selection_range(-1) -- Shrink
      end, 'Shrink selection')
    end
  end,
})

-- ============================================================================
-- ADVANCED FEATURES
-- ============================================================================

-- Auto-format on save
-- vim.api.nvim_create_autocmd('LspAttach', {
--   group = vim.api.nvim_create_augroup('lsp_format_on_save', { clear = true }),
--   callback = function(args)
--     local client = vim.lsp.get_client_by_id(args.data.client_id)
--
--     -- Only enable for specific servers (uncomment and modify as needed)
--     -- if client.name ~= 'lua_ls' then return end
--
--     if client:supports_method('textDocument/formatting') then
--       vim.api.nvim_create_autocmd('BufWritePre', {
--         buffer = args.buf,
--         callback = function()
--           vim.lsp.buf.format({
--             bufnr = args.buf,
--             id = client.id,
--             timeout_ms = 2000,
--           })
--         end,
--       })
--     end
--   end,
-- })

-- Inlay hints (inline parameter names, type hints, etc.)
-- vim.api.nvim_create_autocmd('LspAttach', {
--   group = vim.api.nvim_create_augroup('lsp_inlay_hints', { clear = true }),
--   callback = function(args)
--     local client = vim.lsp.get_client_by_id(args.data.client_id)
--     if client:supports_method('textDocument/inlayHint') then
--       vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
--     end
--   end,
-- })

-- Semantic tokens (enhanced syntax highlighting)
-- Enabled by default, uncomment to disable:
-- vim.api.nvim_create_autocmd('LspAttach', {
--   callback = function(args)
--     vim.lsp.semantic_tokens.enable(false, { bufnr = args.buf })
--   end,
-- })

-- Folding with LSP
-- vim.api.nvim_create_autocmd('LspAttach', {
--   callback = function(args)
--     local client = vim.lsp.get_client_by_id(args.data.client_id)
--     if client:supports_method('textDocument/foldingRange') then
--       vim.wo.foldmethod = 'expr'
--       vim.wo.foldexpr = 'v:lua.vim.lsp.foldexpr()'
--       vim.wo.foldtext = 'v:lua.vim.lsp.foldtext()'
--     end
--   end,
-- })

-- On-type formatting (formats as you type)
-- vim.api.nvim_create_autocmd('LspAttach', {
--   callback = function(args)
--     local client = vim.lsp.get_client_by_id(args.data.client_id)
--     if client.name == 'your_server_name' then
--       vim.lsp.on_type_formatting.enable(true, { client_id = client.id })
--     end
--   end,
-- })

-- Linked editing range (edit matching tags/brackets simultaneously)
-- vim.api.nvim_create_autocmd('LspAttach', {
--   callback = function(args)
--     local client = vim.lsp.get_client_by_id(args.data.client_id)
--     if client:supports_method('textDocument/linkedEditingRange') then
--       vim.lsp.linked_editing_range.enable(true, { client_id = client.id })
--     end
--   end,
-- })
-- -- ============================================================================
-- -- UTILITY FUNCTIONS
-- -- ============================================================================
--
-- -- Restart LSP server
-- vim.api.nvim_create_user_command('LspRestart', function()
--   vim.lsp.stop_client(vim.lsp.get_clients())
--   vim.cmd('edit')
-- end, { desc = 'Restart LSP servers' })
--
-- -- Show LSP info
-- vim.api.nvim_create_user_command('LspInfo', function()
--   local clients = vim.lsp.get_clients({ bufnr = 0 })
--   if #clients == 0 then
--     print('No LSP clients attached to current buffer')
--     return
--   end
--
--   for _, client in ipairs(clients) do
--     print(string.format('Client: %s (id: %d)', client.name, client.id))
--     print('Root dir: ' .. (client.root_dir or 'N/A'))
--     print('Capabilities: ' .. vim.inspect(client.server_capabilities))
--   end
-- end, { desc = 'Show LSP info for current buffer' })
--
-- -- Toggle inlay hints
-- vim.api.nvim_create_user_command('LspInlayHintToggle', function()
--   local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
--   vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
--   print('Inlay hints ' .. (enabled and 'disabled' or 'enabled'))
-- end, { desc = 'Toggle inlay hints' })
--
-- -- Toggle semantic tokens
-- vim.api.nvim_create_user_command('LspSemanticTokensToggle', function()
--   local enabled = vim.lsp.semantic_tokens.is_enabled({ bufnr = 0 })
--   vim.lsp.semantic_tokens.enable(not enabled, { bufnr = 0 })
--   print('Semantic tokens ' .. (enabled and 'disabled' or 'enabled'))
-- end, { desc = 'Toggle semantic tokens' })
--
-- ============================================================================
-- NOTES
-- ============================================================================

--[[
Key Features Configured:
1. Diagnostics with custom signs and floating windows
2. Custom keymaps for all LSP operations
3. Optional auto-format on save
4. Inlay hints, semantic tokens, document colors
5. Code lens, folding, on-type formatting support
6. Utility commands for managing LSP

Important Notes:
- Auto-completion is DISABLED since you use Blink.cmp
- omnifunc is set to nil in LspAttach
- All default buffer-local settings can be overridden
- Global keymaps (gra, gri, etc.) remain unless explicitly deleted

To Use:
1. Uncomment and configure the servers you need
2. Call vim.lsp.enable() for each server
3. Adjust keymaps and features to your preference
4. Run :checkhealth vim.lsp to verify setup

Documentation: :h lsp
--]]
--

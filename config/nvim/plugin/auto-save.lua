-- auto-save

-- Attach to the current buffer (0)
vim.api.nvim_buf_attach(0, false, {
    on_lines = function(event, buf, changed_tick, firstline, lastline, new_lastline, bytecount)
        -- This function will trigger on EVERY modification to the buffer,
        -- including LSP code actions, formatting, and standard typing.

        -- Add your custom logic here
        print("Buffer " .. buf .. " was modified!")
    end
})

vim.api.nvim_create_autocmd("BufModifiedSet", { 
  once = true, 
  callback = function()
    local file_path = vim.fn.expand("<afile>:p:h")
    if vim.bo.buftype == "" and file_path ~= "" and vim.fn.isdirectory(file_path) == 0 then
      vim.fn.mkdir(file_path, "p")
    end
    vim.cmd("silent! write")
    vim.pack.add({ 'https://github.com/pocco81/auto-save.nvim' })
    require('auto-save').setup()
  end 
})


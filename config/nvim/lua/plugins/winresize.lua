return {
  "pogyomo/winresize.nvim",
  config = function()
    local resize = function(win, amt, dir)
      return function()
        require("winresize").resize(win, amt, dir)
      end
    end

    -- Ctrl + 方向鍵 mapping
    vim.keymap.set("n", "<C-Left>",  resize(0, 1, "left"))
    vim.keymap.set("n", "<C-Down>",  resize(0, 1, "down"))
    vim.keymap.set("n", "<C-Up>",    resize(0, 1, "up"))
    vim.keymap.set("n", "<C-Right>", resize(0, 1, "right"))
  end
}


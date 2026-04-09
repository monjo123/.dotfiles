-- kitty-navigator.lua
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name = ev.data.spec.name
    local kind = ev.data.kind

    if name == "kitty-navigator.nvim" and (kind == "install" or kind == "update") then
      local kitty_dir = vim.fn.expand("~/.config/kitty/")
      vim.fn.system({ "cp", "navigate_kitty.py", kitty_dir })
      vim.fn.system({ "cp", "pass_keys.py", kitty_dir })
    end
  end,
})
vim.keymap.set("n", "<A-h>", function() require("kitty-navigator").navigateLeft() end)
vim.keymap.set("n", "<A-j>", function() require("kitty-navigator").navigateUp() end)
vim.keymap.set("n", "<A-k>", function() require("kitty-navigator").navigateDown() end)
vim.keymap.set("n", "<A-l>", function() require("kitty-navigator").navigateRight() end)



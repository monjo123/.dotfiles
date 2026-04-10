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
local function kitty()
  if not package.loaded["kitty-navigator"] then
    vim.pack.add({
      "https://github.com/MunsMan/kitty-navigator.nvim",
    })

    require("kitty-navigator").setup({
      keybindings = {
        left = "<A-h>",
        down = "<A-j>",
        up = "<A-k>",
        right = "<A-l>",
      },
    })
  end
  return require("kitty-navigator")
end
vim.keymap.set("n", "<A-h>", function() kitty().navigateLeft() end)
vim.keymap.set("n", "<A-j>", function() kitty().navigateUp() end)
vim.keymap.set("n", "<A-k>", function() kitty().navigateDown() end)
vim.keymap.set("n", "<A-l>", function() kitty().navigateRight() end)



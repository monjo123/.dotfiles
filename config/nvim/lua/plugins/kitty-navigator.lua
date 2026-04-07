return {
    "MunsMan/kitty-navigator.nvim",
    event = "VeryLazy",
    opts = {
      keybindings = {
        left = "<A-h>",
        down = "<A-j>",
        up = "<A-k>",
        right = "<A-l>",
      }
    },
    build = {
        "cp navigate_kitty.py ~/.config/kitty",
        "cp pass_keys.py ~/.config/kitty",
    },
}

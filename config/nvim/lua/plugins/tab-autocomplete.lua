return {
  {
    "saghen/blink.cmp",
    opts = {
      preset = "super-tab",
      keymap = {
        ["<Tab>"] = { "select_and_accept", "fallback"},
        -- 移除 Enter 的默認行為，防止 <CR> 接受補全
        ["<CR>"] = { "fallback" },
      },
    },
  },
}

-- uv
vim.pack.add({
  "https://github.com/benomahony/uv.nvim",
})

local uv = require("uv")

uv.setup({
  auto_commands = false, 
})

local function activate_project_venv()
  if not uv.is_auto_activate_enabled() then
    return
  end

  local file = vim.api.nvim_buf_get_name(0)
  local start = file ~= "" and vim.fs.dirname(file)
    or vim.fn.getcwd()

  local venv = vim.fs.find(".venv", {
    path = start,
    upward = true,
    type = "directory",
  })[1]

  if not venv or vim.env.VIRTUAL_ENV == venv then
    return
  end

  if vim.env.VIRTUAL_ENV then
    local old_bin = vim.env.VIRTUAL_ENV .. "/bin"
    local paths = {}

    for path in (vim.env.PATH or ""):gmatch("[^:]+") do
      if path ~= old_bin then
        table.insert(paths, path)
      end
    end

    vim.env.PATH = table.concat(paths, ":")
  end

  uv.activate_venv(venv)
end

vim.api.nvim_create_autocmd({ "BufReadPre", "BufEnter" }, {
  pattern = "*.py",
  callback = activate_project_venv,
})

activate_project_venv()

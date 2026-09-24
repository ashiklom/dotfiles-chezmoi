-- Activate `.venv` in the cwd for this nvim session (without needing it active
-- in the shell). This lets ty find the environment, and lets jet.nvim discover
-- and correctly launch the venv's Jupyter kernel (ipykernel's kernelspec runs
-- a bare `python`, so the venv must be on PATH). An externally activated venv
-- takes precedence.

local sep = vim.fn.has("win32") == 1 and ";" or ":"
local bin = vim.fn.has("win32") == 1 and "Scripts" or "bin"
local auto_venv = nil ---@type string?

local function deactivate()
  if not auto_venv then
    return
  end
  local prefix = vim.fs.joinpath(auto_venv, bin) .. sep
  if vim.startswith(vim.env.PATH, prefix) then
    vim.env.PATH = vim.env.PATH:sub(#prefix + 1)
  end
  vim.env.VIRTUAL_ENV = nil
  auto_venv = nil
end

local function activate()
  deactivate()
  if vim.env.VIRTUAL_ENV then
    return
  end
  local venv = vim.fs.joinpath(vim.fn.getcwd(), ".venv")
  if not vim.uv.fs_stat(vim.fs.joinpath(venv, bin, "python")) then
    return
  end
  vim.env.VIRTUAL_ENV = venv
  vim.env.PATH = vim.fs.joinpath(venv, bin) .. sep .. vim.env.PATH
  auto_venv = venv
end

activate()

vim.api.nvim_create_autocmd("DirChanged", {
  group = vim.api.nvim_create_augroup("ans_auto_venv", { clear = true }),
  pattern = "global",
  callback = activate,
})

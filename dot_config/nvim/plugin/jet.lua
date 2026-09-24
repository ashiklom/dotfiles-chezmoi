-- You'll need to include both jet.nvim and jet.ark
vim.pack.add({
  "https://github.com/wurli/jet.nvim",
})

require("jet").setup()

-- A python kernel that doesn't need ipykernel installed anywhere: `uv run
-- --with` layers it (from uv's cache) on top of whichever interpreter uv picks,
-- i.e. the active venv (see plugin/venv.lua) if there is one, otherwise uv's
-- default Python. Venvs with their own ipykernel still take priority.
if vim.fn.executable("uv") == 1 then
  local data_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "uv-kernels")
  local spec_dir = vim.fs.joinpath(data_dir, "kernels", "python3-uv")
  local spec_path = vim.fs.joinpath(spec_dir, "kernel.json")
  local spec = vim.json.encode({
    argv = {
      vim.fn.exepath("uv"), "run", "--no-project", "--with", "ipykernel",
      "python", "-m", "ipykernel_launcher", "-f", "{connection_file}",
    },
    display_name = "Python 3 (uv)",
    language = "python",
  })
  if vim.fn.filereadable(spec_path) == 0 or vim.fn.readfile(spec_path)[1] ~= spec then
    vim.fn.mkdir(spec_dir, "p")
    vim.fn.writefile({ spec }, spec_path)
  end
  local sep = vim.fn.has("win32") == 1 and ";" or ":"
  vim.env.JUPYTER_PATH = data_dir .. (vim.env.JUPYTER_PATH and (sep .. vim.env.JUPYTER_PATH) or "")
end

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = vim.api.nvim_create_augroup("ans_jetrepl", { clear = true }),
  callback = function (args)
    if vim.bo[args.buf].filetype == 'jetrepl' then
      local win = vim.fn.bufwinid(args.buf)
      local width = math.min(100, math.floor(vim.o.columns * 0.5))
      vim.api.nvim_win_set_width(win, width)
    end
  end
})

local M = {}

function M.get_dir()
  local dir = vim.fn.expand('%:p:h')
  if dir == '' then
    dir = vim.uv.cwd()
  end
  return dir
end

function M.get_visual_selection()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    -- not called from visual mode; fall back to the last selection
    mode = vim.fn.visualmode()
  end
  local lines = vim.fn.getregion(vim.fn.getpos("."), vim.fn.getpos("v"), { type = mode })
  return table.concat(lines, "\n")
end

return M

local M = {}

function M.get_visual_selection()
  local region = vim.fn.getregionpos(vim.fn.getpos("."), vim.fn.getpos("v"))[1]
  local bufnum = region[1][1]
  local start_line = region[1][2] - 1
  local start_col = region[1][3] - 1
  local end_line = region[#region][2] - 1
  local end_col = region[#region][3]
  local lines = vim.api.nvim_buf_get_text(bufnum, start_line, start_col, end_line, end_col, {})
  return table.concat(lines, "\n")
end

return M

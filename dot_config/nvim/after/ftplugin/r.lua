require("nvim-treesitter").install({ "r", "markdown", "rnoweb", "yaml" }):wait(300000)
vim.treesitter.start()

local api = require('jet.api')

local function_query = "(binary_operator lhs: (_) rhs: (function_definition)) @func"

local function send_code_to_repl(code)
  if code and code ~= "" then
    api.get_kernel({
      filetype = vim.bo.filetype,
      current = true,
      status = { "connected", "connecting" },
    },
    function(k)
      k:send_repl(code)
    end
  )
  end
end

local function send_selection()
  local start_row = vim.fn.getpos("'<")[2] - 1
  local start_col = vim.fn.getpos("'<")[3] - 1
  local end_row = vim.fn.getpos("'>")[2] - 1
  local end_col = vim.fn.getpos("'>")[3]
  local lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
  local code = table.concat(lines, "\n")
  send_code_to_repl(code)
end

local function goto_expression(dir)
  local pos = api.next_expr_boundary({ direction = dir, boundary = "start" })
  if pos then
    vim.fn.cursor(pos:to_cursor())
  end
end

local function send_expression()
  local expr = api.get_expr()
  if expr then
    local code = expr:code({ comments = false })
    send_code_to_repl(code)
  end
end

local function send_buffer()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local code = table.concat(lines, "\n")
  send_code_to_repl(code)
end

local function send_lines_before_expr()
  local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line(".") - 1, false)
  local code = table.concat(lines, "\n")
  send_code_to_repl(code)
end

local function send_all_functions()
  local ts = vim.treesitter
  local parser = ts.get_parser(0)
  local tree = parser:parse()
  local root = tree[1]:root()
  local query = ts.query.parse(vim.bo.filetype, function_query)

  for _, node, _ in query:iter_captures(root, 0, 0, -1) do
    local start_row, start_col, end_row, end_col = node:range()
    local lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
    local code = table.concat(lines, "\n")
    send_code_to_repl(code)
  end
end

local function send_current_function()
  local expr = api.get_expr()
  if not expr then
    vim.notify("Not on an expression", vim.log.levels.WARN)
    return
  end

  local ts = vim.treesitter
  local parser = ts.get_parser(0)
  if not parser then
    vim.notify("treesitter parser not available", vim.log.levels.WARN)
    return
  end

  local tree = parser:parse()
  local root = tree[1]:root()
  local current_line = vim.fn.line(".") - 1   -- 0-indexed

  local function_node = nil
  local query = ts.query.parse(vim.bo.filetype, function_query)

  for _, node, _ in query:iter_captures(root, 0, 0, -1) do
    local start_row, _, end_row, _ = node:range()
    -- Check if cursor is within this function
    if start_row <= current_line and current_line <= end_row then
      function_node = node
      break
    end
  end

  if not function_node then
    vim.notify("No funciton definition found", vim.log.levels.WARN)
    return
  end

  local start_row, _, end_row, _ = function_node:range()
  local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
  local code = table.concat(lines, "\n")
  send_code_to_repl(code)
end

local function call_fn_on_cword(fn)
  local word = vim.fn.expand("<cword>")
  if word and word ~= "" then
    send_code_to_repl(string.format("%s(%s)", fn, word))
  end
end

vim.keymap.set(
  "n",
  "<localleader>rf",
  function() require('jet.api').get_kernel({filetype = 'r'}, function(k) k:term_toggle() end) end,
  { desc = "Toggle R REPL", buffer = 0 }
)
vim.keymap.set(
  "n",
  "<localleader>rq",
  function() require('jet.api').get_kernel({filetype = 'r'}, function(k) k:close() end) end,
  { desc = "Close R REPL", buffer = 0 }
)

vim.keymap.set("n", "<localleader>l", send_expression, { desc = "Send current expression to R", buffer = 0 })
vim.keymap.set("x", "<localleader>ss", send_selection, { desc = "Send visual selection to R", buffer = 0 })
vim.keymap.set("n", "<localleader>d", function()
  send_expression()
  goto_expression(1)
end, { desc = "Send expression and goto next", buffer = 0 })
vim.keymap.set("n", "<localleader>aa", send_buffer, { desc = "Send buffer to R", buffer = 0 })
vim.keymap.set("n", "<localleader>su", send_lines_before_expr, { desc = "Send lines above to R", buffer = 0 })

vim.keymap.set("n", "]e", function() goto_expression(1) end, { desc = "Next expression", buffer = 0 })
vim.keymap.set("n", "[e", function() goto_expression(-1) end, { desc = "Previous expression", buffer = 0 })

vim.keymap.set("n", "<localleader>fc", send_current_function, { desc = "Send current function", buffer = 0 })
vim.keymap.set("n", "<localleader>fd", function()
  send_current_function()
  goto_expression(1)
end, { desc = "Send current function and down", buffer = 0 })
vim.keymap.set("n", "<localleader>fa", send_all_functions, { desc = "Send all functions", buffer = 0 })

vim.keymap.set("n", "<localleader>rp", function() call_fn_on_cword("print") end, { desc = "Print object under cursor", buffer = 0 })
vim.keymap.set("n", "<localleader>rg", function() call_fn_on_cword("dplyr::glimpse") end, { desc = "dplyr::glimpse object under cursor", buffer = 0 })
vim.keymap.set("n", "<localleader>rn", function() call_fn_on_cword("names") end, { desc = "`names` of object under cursor", buffer = 0 })
vim.keymap.set("n", "<localleader>rs", function() call_fn_on_cword("str") end, { desc = "`str` of object under cursor", buffer = 0 })

vim.keymap.set("i", "<M-.>", " |> ", { desc = "Insert |>", buffer = 0 })
vim.keymap.set("i", "<M-->", " <- ", { desc = "Insert <-", buffer = 0 })
vim.keymap.set("i", "<M-i>", " %in% ", { desc = "Insert '%in%'", buffer = 0 })

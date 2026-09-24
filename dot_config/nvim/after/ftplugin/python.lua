require('nvim-treesitter').install({ "python" })

vim.lsp.config("ruff", {
  on_attach = function(client, _)
    client.server_capabilities.hoverProvider = false
  end
})

local uv_script = require('ans-uv-script')

-- uv scripts get a separate ty client using the script's environment
vim.lsp.config("ty", { root_dir = uv_script.ty_root_dir })

vim.lsp.enable({"ty", "ruff"})

uv_script.attach(0)

vim.pack.add({
  "https://github.com/wurli/jet.ipy"
})
require('jet.ipy').setup()

-- jet.nvim only resolves a kernel's filetype after it starts, so inactive
-- kernels never match a `filetype` filter. Set it from the kernelspec instead.
require('jet').hooks.on_kernel_init.python_filetype = function(k)
  if not k.filetype and k.spec and (k.spec.language or ""):lower() == "python" then
    k.filetype = "python"
  end
end

local api = require('jet.api')
local au = require('ans-utils')

local function_query = "(function_definition) @func"

-- jet.ipy uses vim.treesitter.get_node(), which doesn't parse the buffer, so
-- the tree must be parsed first (treesitter highlighting isn't started here).
local function ts_parse()
  local parser = vim.treesitter.get_parser(0, nil, { error = false })
  if parser then
    parser:parse()
  end
end

-- For uv scripts, return the running kernel for the script's environment
-- (starting one if `start`). Returns nil for other buffers.
---@return { kernel: jet.Kernel? }?
local function script_kernel(start)
  if not uv_script.metadata(0) then
    return nil
  end
  local script = vim.b.uv_script
  if not script then
    vim.notify("uv script environment isn't ready yet", vim.log.levels.WARN)
    return {}
  end
  local running = api.list_kernels({ spec_path = script.spec_path, status = { "connected", "connecting" } })
  local k = running[1]
  if not k and start then
    k = require('jet.core.kernel').init_owned({ spec_path = script.spec_path })
  end
  return { kernel = k }
end

local function send_code_to_repl(code)
  if code and code ~= "" then
    local script = script_kernel(false)
    if script then
      if script.kernel then
        script.kernel:send_repl(code)
      end
      return
    end
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

local function goto_expression(dir)
  ts_parse()
  local pos = api.next_expr_boundary({ direction = dir, boundary = "start" })
  if pos then
    vim.fn.cursor(pos:to_cursor())
  end
end

local function send_expression()
  ts_parse()
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
  ts_parse()
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
  function()
    local script = script_kernel(true)
    if script then
      if script.kernel then script.kernel:term_toggle() end
      return
    end
    api.get_kernel({filetype = 'python'}, function(k) k:term_toggle() end)
  end,
  { desc = "Toggle REPL", buffer = 0 }
)
vim.keymap.set(
  "n",
  "<localleader>rq",
  function()
    local script = script_kernel(false)
    if script then
      if script.kernel then script.kernel:close() end
      return
    end
    api.get_kernel({filetype = 'python'}, function(k) k:close() end)
  end,
  { desc = "Close REPL", buffer = 0 }
)

vim.keymap.set("n", "<localleader>l", send_expression, { desc = "Send current expression", buffer = 0 })
vim.keymap.set(
  "x",
  "<localleader>ss",
  function() send_code_to_repl(au.get_visual_selection()) end,
  { desc = "Send visual selection", buffer = 0 }
)
vim.keymap.set("n", "<localleader>d", function()
  send_expression()
  goto_expression(1)
end, { desc = "Send expression and goto next", buffer = 0 })
vim.keymap.set("n", "<localleader>aa", send_buffer, { desc = "Send buffer", buffer = 0 })
vim.keymap.set("n", "<localleader>su", send_lines_before_expr, { desc = "Send lines above", buffer = 0 })

vim.keymap.set("n", "]e", function() goto_expression(1) end, { desc = "Next expression", buffer = 0 })
vim.keymap.set("n", "[e", function() goto_expression(-1) end, { desc = "Previous expression", buffer = 0 })

vim.keymap.set("n", "<localleader>fc", send_current_function, { desc = "Send current function", buffer = 0 })
vim.keymap.set("n", "<localleader>fd", function()
  send_current_function()
  goto_expression(1)
end, { desc = "Send current function and down", buffer = 0 })
vim.keymap.set("n", "<localleader>fa", send_all_functions, { desc = "Send all functions", buffer = 0 })

vim.keymap.set("n", "<localleader>rp", function() call_fn_on_cword("print") end, { desc = "Print object under cursor", buffer = 0 })

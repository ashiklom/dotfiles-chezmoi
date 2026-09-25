-- Shared jet.nvim REPL setup for language ftplugins: sending code, expression
-- motions, function sending, and the keymaps for all of these. Works both in
-- plain source files and in documents with embedded code cells (e.g. quarto).
local M = {}

local au = require('ans-utils')

---@class ans.repl.Lang
---@field name string Language name used in keymap descriptions

---Supported languages. Their jet.nvim extensions (jet.ark, jet.ipy) are loaded
---by the ftplugins.
---@type table<string, ans.repl.Lang>
M.languages = {
  r = { name = "R" },
  python = { name = "Python" },
}

---@class ans.repl.Overrides
---Buffer-specific kernel override. Return `true` if it handled the request
---(calling `callback` with a kernel if there is one); otherwise the usual
---filetype-based lookup is used.
---@field buf_kernel? fun(start: boolean, callback: fun(k: jet.Kernel)): boolean

-- Buffer -> function returning the REPL handlers for the cursor position, as
-- registered by `setup()` / `setup_embedded()`. Used by `send_code()`.
---@type table<integer, fun(): table?>
local buf_handlers = {}

---@param resolve fun(): table?
local function register(resolve)
  local buf = vim.api.nvim_get_current_buf()
  buf_handlers[buf] = resolve
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = vim.api.nvim_create_augroup("ans_repl_" .. buf, { clear = true }),
    buffer = buf,
    callback = function() buf_handlers[buf] = nil end,
  })
end

-- jet's expression detection uses vim.treesitter.get_node(), which only reads
-- an already-parsed tree and never parses the buffer itself. Parse fully so
-- injected code (e.g. quarto cells) is included.
local function ts_parse()
  local parser = vim.treesitter.get_parser(0, nil, { error = false })
  if parser then
    parser:parse(true)
  end
  return parser
end

---Code cells of supported languages in the current buffer (via otter.nvim),
---in buffer order, or nil if the buffer has no embedded code.
---@return { lang: string, first: integer, last: integer, text: string[] }[]?
local function code_cells()
  local ok, keeper = pcall(require, 'otter.keeper')
  local buf = vim.api.nvim_get_current_buf()
  if not ok or M.languages[vim.bo.filetype] or keeper.sync_raft(buf) == "no_raft" then
    return
  end
  local cells = {}
  for lang, chunks in pairs(keeper.rafts[buf].code_chunks) do
    if M.languages[lang] then
      for _, chunk in ipairs(chunks) do
        local first = chunk.range.from[1]
        table.insert(cells, { lang = lang, first = first, last = first + #chunk.text - 1, text = chunk.text })
      end
    end
  end
  table.sort(cells, function(a, b) return a.first < b.first end)
  return cells
end

-- jet resolves the language at each position itself, so this works for any
-- language. In documents with code cells, jet's motion can escape a cell
-- (e.g. jumping back from its last expression), so it's only used within
-- the current cell; past the cell's edge, go to the adjacent cell instead.
local function goto_expression(dir)
  local api = require('jet.api')
  ts_parse()
  local cells = code_cells()
  if not cells then
    local pos = api.next_expr_boundary({ direction = dir, boundary = "start" })
    if pos then
      vim.fn.cursor(pos:to_cursor())
    end
    return
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1
  local current
  for _, cell in ipairs(cells) do
    if cell.first <= row and row <= cell.last then
      current = cell
    end
  end

  if current then
    local pos = api.next_expr_boundary({ direction = dir, boundary = "start" })
    local moved = pos and (dir > 0 and (pos.row > row or pos.row == row and pos.col > col)
      or dir < 0 and (pos.row < row or pos.row == row and pos.col < col))
    if moved and current.first <= pos.row and pos.row <= current.last then
      vim.fn.cursor(pos:to_cursor())
      return
    end
  end

  local target
  for i = dir > 0 and 1 or #cells, dir > 0 and #cells or 1, dir do
    local cell = cells[i]
    if dir > 0 and cell.first > (current and current.last or row)
      or dir < 0 and cell.last < (current and current.first or row) then
      target = cell
      break
    end
  end
  if not target then
    return
  end

  -- First non-blank line of the next cell, or start of the previous cell's
  -- last expression
  local first, last, step = 1, #target.text, 1
  if dir < 0 then
    first, last, step = last, first, -1
  end
  for i = first, last, step do
    local c = target.text[i]:find("%S")
    if c then
      local target_row = target.first + i - 1
      vim.fn.cursor(target_row + 1, c)
      if dir < 0 then
        local expr = api.get_expr()
        if expr and expr:start().row >= target.first then
          vim.fn.cursor(expr:start():to_cursor())
        end
      end
      return
    end
  end
end

---Code in language `ft` from the current buffer, optionally only the rows
---before `end_row` (0-indexed, exclusive). If `ft` is embedded in another
---filetype (e.g. quarto), only the lines of `ft` code cells are included.
---@param ft string
---@param end_row? integer
---@return string?
local function buffer_code(ft, end_row)
  if vim.bo.filetype == ft then
    return table.concat(vim.api.nvim_buf_get_lines(0, 0, end_row or -1, false), "\n")
  end

  local keeper = require('otter.keeper')
  local buf = vim.api.nvim_get_current_buf()
  if keeper.sync_raft(buf) == "no_raft" then
    vim.notify("otter isn't active in this buffer", vim.log.levels.WARN)
    return
  end
  local lang = vim.treesitter.language.get_lang(ft) or ft
  local lines = {}
  for _, chunk in ipairs(keeper.rafts[buf].code_chunks[lang] or {}) do
    local from = chunk.range.from[1]
    if end_row and from >= end_row then
      break
    end
    local n = end_row and math.min(#chunk.text, end_row - from) or #chunk.text
    vim.list_extend(lines, chunk.text, 1, n)
  end
  return table.concat(lines, "\n")
end

---REPL actions for language `ft`, for the current buffer.
---@param ft string
---@param function_query? string Treesitter query capturing function definitions as `@func`
---@param overrides? ans.repl.Overrides
function M.handlers(ft, function_query, overrides)
  local spec = assert(M.languages[ft], "No REPL config for filetype " .. ft)
  overrides = overrides or {}
  local api = require('jet.api')

  -- jet.nvim only resolves a kernel's filetype after it starts, so inactive
  -- kernels never match a `filetype` filter. Set it from the kernelspec instead.
  require('jet').hooks.on_kernel_init["ans_filetype_" .. ft] = function(k)
    if not k.filetype and k.spec and (k.spec.language or ""):lower() == ft then
      k.filetype = ft
    end
  end

  ---@param filters jet.api.Filters
  ---@param start boolean Whether a buffer-specific kernel may be started
  ---@param callback fun(k: jet.Kernel)
  local function with_kernel(filters, start, callback)
    if overrides.buf_kernel and overrides.buf_kernel(start, callback) then
      return
    end
    api.get_kernel(vim.tbl_extend("force", { filetype = ft }, filters), callback)
  end

  local function send(code)
    if code and code ~= "" then
      with_kernel({ current = true, status = { "connected", "connecting" } }, false, function(k)
        k:send_repl(code)
      end)
    end
  end

  local function send_expression()
    ts_parse()
    local expr = api.get_expr()
    if expr then
      send(expr:code({ comments = false }))
    end
  end

  -- Function definitions in `ft` code, including code injected into other
  -- languages, in buffer order.
  local function function_nodes()
    if not function_query then
      vim.notify("No function query for " .. spec.name, vim.log.levels.WARN)
      return {}
    end
    local parser = ts_parse()
    if not parser then
      vim.notify("treesitter parser not available", vim.log.levels.WARN)
      return {}
    end
    local lang = vim.treesitter.language.get_lang(ft) or ft
    local query = vim.treesitter.query.parse(lang, function_query)
    local nodes = {}
    parser:for_each_tree(function(tree, ltree)
      if ltree:lang() == lang then
        for _, node in query:iter_captures(tree:root(), 0) do
          table.insert(nodes, node)
        end
      end
    end)
    table.sort(nodes, function(a, b) return a:start() < b:start() end)
    return nodes
  end

  local function send_current_function()
    local current_line = vim.fn.line(".") - 1   -- 0-indexed
    for _, node in ipairs(function_nodes()) do
      local start_row, _, end_row, _ = node:range()
      if start_row <= current_line and current_line <= end_row then
        local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
        send(table.concat(lines, "\n"))
        return
      end
    end
    vim.notify("No function definition found", vim.log.levels.WARN)
  end

  return {
    name = spec.name,
    send = send,
    toggle_repl = function() with_kernel({}, true, function(k) k:term_toggle() end) end,
    close_repl = function() with_kernel({}, false, function(k) k:close() end) end,
    send_expression = send_expression,
    send_expression_and_next = function()
      send_expression()
      goto_expression(1)
    end,
    send_visual = function() send(au.get_visual_selection()) end,
    send_buffer = function() send(buffer_code(ft)) end,
    send_lines_above = function() send(buffer_code(ft, vim.fn.line(".") - 1)) end,
    send_current_function = send_current_function,
    send_function_and_next = function()
      send_current_function()
      goto_expression(1)
    end,
    send_all_functions = function()
      for _, node in ipairs(function_nodes()) do
        local start_row, start_col, end_row, end_col = node:range()
        local lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
        send(table.concat(lines, "\n"))
      end
    end,
  }
end

-- { mode, lhs (after <localleader>), handler, description (%s = language name) }
local keymaps = {
  { "n", "rf", "toggle_repl", "Toggle %s REPL" },
  { "n", "rq", "close_repl", "Close %s REPL" },
  { "n", "l", "send_expression", "Send current expression to %s" },
  { "x", "ss", "send_visual", "Send visual selection to %s" },
  { "n", "d", "send_expression_and_next", "Send expression and goto next" },
  { "n", "aa", "send_buffer", "Send buffer to %s" },
  { "n", "su", "send_lines_above", "Send lines above to %s" },
  { "n", "fc", "send_current_function", "Send current function" },
  { "n", "fd", "send_function_and_next", "Send current function and down" },
  { "n", "fa", "send_all_functions", "Send all functions" },
}

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc, buffer = 0 })
end

local function map_motions()
  map("n", "]e", function() goto_expression(1) end, "Next expression")
  map("n", "[e", function() goto_expression(-1) end, "Previous expression")
end

---Set up REPL keymaps for a buffer of filetype `ft`.
---@param ft string
---@param function_query string Treesitter query capturing function definitions as `@func`
---@param overrides? ans.repl.Overrides
function M.setup(ft, function_query, overrides)
  local h = M.handlers(ft, function_query, overrides)
  register(function() return h end)
  for _, km in ipairs(keymaps) do
    map(km[1], "<localleader>" .. km[2], h[km[3]], km[4]:format(h.name))
  end
  map_motions()
end

---Set up REPL keymaps for a document with embedded code cells (via otter.nvim),
---each dispatching to the language of the cell under the cursor.
---@param function_queries table<string, string> Filetype -> function query (see `setup()`)
function M.setup_embedded(function_queries)
  local hs = {}
  local names = {}
  for ft, function_query in vim.spairs(function_queries) do
    hs[ft] = M.handlers(ft, function_query)
    table.insert(names, hs[ft].name)
  end
  local names_str = table.concat(names, "/")

  -- Language of the cell under the cursor; outside of cells, the only
  -- supported language in the document if there's just one.
  local function current()
    local keeper = require('otter.keeper')
    local lang = keeper.get_current_language_context()
    if lang and hs[lang] then
      return hs[lang]
    end
    local raft = keeper.rafts[vim.api.nvim_get_current_buf()]
    local present = vim.tbl_filter(function(l) return hs[l] ~= nil end, raft and raft.languages or {})
    if not lang and #present == 1 then
      return hs[present[1]]
    end
    vim.notify("Not in a " .. names_str .. " code cell", vim.log.levels.WARN)
  end

  register(current)
  for _, km in ipairs(keymaps) do
    map(km[1], "<localleader>" .. km[2], function()
      local h = current()
      if h then h[km[3]]() end
    end, km[4]:format(names_str))
  end
  map_motions()

  return hs
end

---Send code to the REPL for the current buffer (or, in documents with code
---cells, the language of the cell under the cursor).
---@param code string|string[]
function M.send_code(code)
  local resolve = buf_handlers[vim.api.nvim_get_current_buf()]
  if not resolve then
    vim.notify("No REPL set up for this buffer", vim.log.levels.WARN)
    return
  end
  local h = resolve()
  if h then
    h.send(code)
  end
end

---Send `fmt` with `%s` replaced by the word under the cursor, e.g.
---`send_cword("print(%s)")`.
---@param fmt string
function M.send_cword(fmt)
  local word = vim.fn.expand("<cword>")
  if word and word ~= "" then
    M.send_code(fmt:format(word))
  end
end

return M

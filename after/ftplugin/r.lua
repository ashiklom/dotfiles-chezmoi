require("nvim-treesitter").install({ "r", "markdown", "rnoweb", "yaml" }):wait(300000)
vim.treesitter.start()

local api = require('jet.api')

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

local function send_expression()
  local expr = api.get_expr()
  if not expr then
    local pos = api.next_expr_boundary({current_ok = false, boundary = "start"})
    expr = pos and api.get_expr(pos)
  end
  if expr then
    local code = expr:code({ comments = false })
    send_code_to_repl(code)
  end
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

vim.keymap.set("n", "<localleader>l", send_expression, { desc = "Send current expression to R" })
vim.keymap.set("x", "<localleader>ss", send_selection, { desc = "Send visual selection to R" })
vim.keymap.set("n", "<localleader>rp", function() call_fn_on_cword("print") end, { desc = "Print object under cursor", buffer = 0 })
vim.keymap.set("n", "<localleader>rg", function() call_fn_on_cword("dplyr::glimpse") end, { desc = "dplyr::glimpse object under cursor", buffer = 0 })
vim.keymap.set("n", "<localleader>rn", function() call_fn_on_cword("names") end, { desc = "`names` of object under cursor", buffer = 0 })
vim.keymap.set("n", "<localleader>rs", function() call_fn_on_cword("str") end, { desc = "`str` of object under cursor", buffer = 0 })

vim.keymap.set("i", "<M-.>", " |> ", { desc = "Insert |>" })
vim.keymap.set("i", "<M-->", " -> ", { desc = "Insert ->" })
vim.keymap.set("i", "<M-i>", " %in% ", { desc = "Insert ->" })

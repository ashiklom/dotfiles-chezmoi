vim.pack.add({
  "https://github.com/quarto-dev/quarto-nvim",
  "https://github.com/jmbuhr/otter.nvim"
})

vim.treesitter.language.register('markdown', 'quarto')
require('nvim-treesitter').install({ "markdown", "markdown_inline", "r", "python", "yaml" })

-- jet.ark's setup adds a kernel hook each time it runs, so only run it once
if not vim.g.ans_jet_ark_setup then
  vim.pack.add({
    "https://github.com/wurli/jet.ark",
  })
  require("jet.ark").setup({
    ark_binary_path = "~/.local/bin/ark",
  })
  vim.g.ans_jet_ark_setup = true
end
if not vim.g.ans_jet_ipy_setup then
  vim.pack.add({
    "https://github.com/wurli/jet.ipy"
  })
  require('jet.ipy').setup()
  vim.g.ans_jet_ipy_setup = true
end

local repl = require('ans-repl')

require('quarto').setup({
  codeRunner = {
    enabled = true,
    -- Send cells to jet.nvim kernels (jet.ark for R, jet.ipy for Python)
    default_method = function(cell, _)
      if not repl.languages[cell.lang] then
        vim.notify("[Quarto] no jet runner for language: " .. tostring(cell.lang), vim.log.levels.WARN)
        return
      end
      repl.handlers(cell.lang).send(table.concat(cell.text, "\n"))
    end,
  },
})

local ok, otter = pcall(require, 'otter')
if ok then
  otter.activate()
end

-- Code running ---------------------------------------------------------------

-- The usual R/Python REPL keymaps, acting on the language of the current cell
repl.setup_embedded({
  r = "(binary_operator lhs: (_) rhs: (function_definition)) @func",
  python = "(function_definition) @func",
})
vim.keymap.set("n", "<localleader>rp", function() repl.send_cword("print(%s)") end,
  { desc = "Print object under cursor", buffer = true })

local runner = require('quarto.runner')
vim.keymap.set("n", "<localleader>cc", runner.run_cell, { buffer = true, desc = "Run cell" })
vim.keymap.set("n", "<localleader>cu", runner.run_above, { buffer = true, desc = "Run cell and above" })
vim.keymap.set("n", "<localleader>cd", runner.run_below, { buffer = true, desc = "Run cell and below" })
vim.keymap.set("n", "<localleader>cA", function() runner.run_all(true) end,
  { buffer = true, desc = "Run all cells (all languages)" })

vim.opt_local.wrap = true

-- Section navigation ---------------------------------------------------------

local section_query = vim.treesitter.query.parse('markdown', '(section) @section')

local function goto_section(dir)
  return function()
    local cur = vim.api.nvim_win_get_cursor(0)[1] - 1
    local rows = {}
    local ok_parser, parser = pcall(vim.treesitter.get_parser, 0)
    if not ok_parser or not parser then return end
    for _, node in section_query:iter_captures(parser:parse()[1]:root(), 0) do
      rows[node:start()] = true
    end
    local sorted = vim.tbl_keys(rows)
    table.sort(sorted)
    local target
    for _ = 1, vim.v.count1 do
      local nxt
      if dir > 0 then
        for _, r in ipairs(sorted) do
          if r > cur then nxt = r; break end
        end
      else
        for i = #sorted, 1, -1 do
          if sorted[i] < cur then nxt = sorted[i]; break end
        end
      end
      if not nxt then break end
      cur, target = nxt, nxt
    end
    if target then
      vim.cmd("normal! m'")
      vim.api.nvim_win_set_cursor(0, { target + 1, 0 })
    end
  end
end

vim.keymap.set({ 'n', 'x', 'o' }, ']]', goto_section(1), { buffer = true, desc = "Next section" })
vim.keymap.set({ 'n', 'x', 'o' }, '[[', goto_section(-1), { buffer = true, desc = "Previous section" })

-- mini.ai textobjects (captures in after/queries/markdown/textobjects.scm) ---

local mai = require('mini.ai')
vim.b.miniai_config = {
  custom_textobjects = {
    S = mai.gen_spec.treesitter({ a = '@section.outer', i = '@section.outer' }),
    c = mai.gen_spec.treesitter({ a = '@codeblock.outer', i = '@codeblock.inner' }),
  },
}

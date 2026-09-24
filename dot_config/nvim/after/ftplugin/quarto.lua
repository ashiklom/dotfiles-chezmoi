vim.pack.add({
  "https://github.com/quarto-dev/quarto-nvim",
  "https://github.com/jmbuhr/otter.nvim"
})

vim.treesitter.language.register('markdown', 'quarto')

require('quarto').setup({})

local ok, otter = pcall(require, 'otter')
if ok then
  otter.activate()
end

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

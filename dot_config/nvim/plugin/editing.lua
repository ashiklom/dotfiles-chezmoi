vim.pack.add({
  'https://github.com/kylechui/nvim-surround',
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
})

-- Visual line navigation
vim.keymap.set({'n', 'v'}, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set({'n', 'v'}, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({'n', 'v'}, 'gk', "v:count == 0 ? 'k' : 'gk'", { expr = true, silent = true })
vim.keymap.set({'n', 'v'}, 'gj', "v:count == 0 ? 'j' : 'gj'", { expr = true, silent = true })

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup('ansauto_fo', { clear = true }),
  callback = function()
    vim.opt_local.formatoptions:remove({"o"})
  end
})

-- Leap
vim.pack.add({ 'https://codeberg.org/andyg/leap.nvim' })
vim.keymap.set('n', 's', '<Plug>(leap-forward)', { desc = "Leap forward" })
vim.keymap.set('n', 'S', '<Plug>(leap-backward)', { desc = "Leap backward" })

vim.pack.add({
  'https://github.com/nvim-mini/mini.ai',
})
local mai = require('mini.ai')
require('mini.ai').setup({
  n_lines = 500,
  mappings = {goto_left = "g.", goto_right = "g,"},
  custom_textobjects = {
    o = mai.gen_spec.treesitter({ -- code block
      a = { "@block.outer", "@conditional.outer", "@loop.outer" },
      i = { "@block.inner", "@conditional.inner", "@loop.inner" },
    }),
    f = mai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
    c = mai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
    t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
    d = { "%f[%d]%d+" }, -- digits
    e = { -- Word with case
      { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
      "^().*()$",
    },
    u = mai.gen_spec.function_call(), -- u for "Usage"
    U = mai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
  }
})

vim.pack.add({ 'https://github.com/nvim-mini/mini.move' })
require('mini.move').setup({
  mappings = {
    left = "<S-left>",
    right = "<S-right>",
    up = "<S-up>",
    down = "<S-down>",
    line_left = "<S-left>",
    line_right = "<S-right>",
    line_up = "<S-up>",
    line_down = "<S-down>"
  }
})

vim.pack.add({ 'https://github.com/nvim-mini/mini.pairs' })
require('mini.pairs').setup()

vim.pack.add({ 'https://github.com/nvim-mini/mini.splitjoin' })
require('mini.splitjoin').setup({
  mappings = {
    toggle = 'g[',
    split = 'g{',
    join = 'g}'
  }
})

-- vim.pack.add({'https://github.com/nvim-mini/mini.cmdline'})
-- require('mini.cmdline').setup()

-- Splitjoin
vim.keymap.set('i', '<C-]>', function() require('mini.splitjoin').toggle() end, {desc = "Toggle splitjoin"})

-- Conform
vim.pack.add({'https://github.com/stevearc/conform.nvim'})
require('conform').setup({
  formatters_by_ft = {
    lua = {"stylua"},
    python = {"isort", "black"},
    r = {"air"},
    hcl = {"hclfmt"},
    sh = {"shfmt"}
  },
  default_format_opts = {
    lsp_format = "fallback"
  },
})

vim.keymap.set({"n", "x"}, "<leader>fm", function() require('conform').format({async = true}) end, {desc = "Format buffer or selection"})

vim.pack.add({"https://github.com/chrisgrieser/nvim-scissors"})
require('scissors').setup({
  snippetDir = vim.fn.stdpath("config") .. "/snippets"
})
vim.keymap.set("n", "<leader>ne", function() require('scissors').editSnippet() end, { desc = "Edit snippet" })
vim.keymap.set({"n", "x"}, "<leader>na", function() require('scissors').addNewSnippet() end, { desc = "Add new snippet" })

-- Enable treesitter by default
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("ans_treesitter", { clear = true }),
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
  end,
})

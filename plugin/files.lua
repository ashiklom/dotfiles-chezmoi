vim.pack.add({ 'https://github.com/nvim-mini/mini.icons' })
require('mini.icons').setup()

vim.pack.add({ 'https://github.com/nvim-mini/mini.bufremove' })
require('mini.bufremove').setup()

vim.pack.add({'https://github.com/stevearc/oil.nvim'})
require('oil').setup({
  buf_options = {
    buflisted = false,
    bufhidden = "hide"
  },
  cleanup_delay_ms = 2000
})


vim.keymap.set('n', "<leader>fs", vim.cmd.write, {desc = "Save file"})
vim.keymap.set('n', "<leader>fo", function() vim.cmd.edit('.') end, {desc = "Open file directory"})

vim.keymap.set('i', 'jk', '<ESC>', {desc = "Normal mode"})
vim.keymap.set('n', '<ESC>', vim.cmd.nohlsearch)
vim.keymap.set('n', 'z.', 'zszH', {desc = "Center horizontally on character"})
vim.keymap.set('n', 'gb', '<C-^>', {desc = "Most recent buffer"})

vim.keymap.set('n', "<leader>w-", vim.cmd.split, {desc = "Split window down"})
vim.keymap.set('n', "<leader>w\\", vim.cmd.vsplit, {desc = "Split window down"})
vim.keymap.set('n', "<leader>wd", vim.cmd.close, {desc = "Split window down"})
vim.keymap.set('n', "<leader>wj", function() vim.cmd.wincmd("j") end, {desc = "Goto window below"})
vim.keymap.set('n', "<leader>wk", function() vim.cmd.wincmd("k") end, {desc = "Goto window above"})
vim.keymap.set('n', "<leader>wh", function() vim.cmd.wincmd("h") end, {desc = "Goto window left"})
vim.keymap.set('n', "<leader>wl", function() vim.cmd.wincmd("l") end, {desc = "Goto window right"})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("spelling", { clear = true }),
  pattern = {
    "gitcommit",
    "markdown",
    "org",
    "plaintex",
    "quarto",
    "tex",
    "text",
  },
  command = "setlocal spell wrap"
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup('close_with_q', { clear = true }),
  pattern = {
    "help",
    "lspinfo",
    "notify",
    "qf",
    "checkhealth",
    "grug-far",
    "nvim-pack",
    "oil"
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", {
      buffer = event.buf,
      silent = true,
      desc = "Quit buffer"
    })
  end
})

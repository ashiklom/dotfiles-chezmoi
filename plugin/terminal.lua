vim.pack.add({
  'https://github.com/akinsho/toggleterm.nvim',
})

require('toggleterm').setup({
  direction = "horizontal"
})

-- Terminal -- escpae with <esc><esc>
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("ansauto_esc2", {clear = true}),
  pattern = {"term://*"},
  callback = function()
    vim.keymap.set('t', '<esc><esc>', [[<C-\><C-n>]], {buffer=true, nowait=true})
  end
})

-- ...except for these filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("ansauto_noesc2", {clear = true}),
  pattern = {"fzf"},
  callback = function()
    vim.keymap.del('t', '<esc><esc>', {buffer=true})
  end
})

vim.keymap.set('n', '<C-\\>', function() require('toggleterm').toggle() end, {desc = "Toggleterm"})

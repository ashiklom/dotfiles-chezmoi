vim.pack.add({
  'https://github.com/akinsho/toggleterm.nvim',
})

require('toggleterm').setup({
  direction = "horizontal"
})


-- Terminal -- escape with <esc><esc>, except for the filetypes here
local no_esc = {fzf = true, lazygit = true}
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("ansauto_esc2", {clear = true}),
  pattern = {"term://*"},
  callback = function(ev)
    if no_esc[vim.bo[ev.buf].filetype] then
      return
    end
    if vim.api.nvim_buf_get_name(ev.buf):find("lazygit", 1, true) then
      return
    end
    vim.keymap.set('t', '<esc><esc>', [[<C-\><C-n>]], {buffer=true, nowait=true})
  end
})

vim.keymap.set('n', '<C-\\>', function() require('toggleterm').toggle() end, {desc = "Toggleterm"})

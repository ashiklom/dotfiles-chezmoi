require('nvim-treesitter').install({ "bash" })
vim.lsp.enable({ "bashls" })

vim.bo.keywordprg = ":Man"

vim.keymap.set("n", "<localleader>rf", function() require('toggleterm').toggle() end, { desc = "Toggle terminal" })

vim.keymap.set(
  "n",
  "<localleader>l",
  function() require('toggleterm').send_lines_to_terminal('single_line', true, { args = vim.v.count }) end,
  { desc = "Send line to terminal" }
)

vim.keymap.set(
  "v",
  "<localleader>ss",
  function() require('toggleterm').send_lines_to_terminal('visual_selection', true, { args = vim.v.count }) end,
  { desc = "Send selection to terminal" }
)

vim.keymap.set(
  "n",
  "<localleader>rp",
  function() require('toggleterm').exec("echo $" .. vim.fn.expand('<cword>'), 1) end,
  { desc = "Echo current variable" }
)

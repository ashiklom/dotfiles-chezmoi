vim.pack.add({
  "https://github.com/wurli/jet.nvim",
  "https://github.com/folke/snacks.nvim"
})

require('snacks').setup({
  bigfile = {},
  image = {},
  indent = { animate = { enabled = false }},
  lazygit = {},
  rename = {},
  zen = {}
})

vim.keymap.set("n", "<leader>lg", function() Snacks.lazygit.open() end, { desc = "Lazygit" })
vim.keymap.set("n", "<leader>z", function() Snacks.zen.zoom() end, { desc = "Toggle zoom" })
vim.keymap.set("n", "<leader>fR", function() Snacks.rename.rename_file() end, { desc = "Rename file" })

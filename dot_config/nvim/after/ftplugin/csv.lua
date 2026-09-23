vim.pack.add({ "https://github.com/hat0uma/csvview.nvim" })
require('csvview').setup({
  keymaps = {
    jump_next_field_end = { "<Right>", mode = { "n", "x" }},
    jump_prev_field_end = { "<Left>", mode = { "n", "x" }},
    jump_next_row = { "<Down>", mode = { "n", "x" }},
    jump_prev_row = { "<Up>", mode = { "n", "x" } }
  }
})

vim.keymap.set(
  {"n", "x"},
  "<localleader>T",
  function() require('csvview').toggle(0, {view = {display_mode = "border"}, header_lnum = 1}) end,
  { desc = "Toggle CSVview", buffer = 0 }
)

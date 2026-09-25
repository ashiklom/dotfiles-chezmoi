require("nvim-treesitter").install({ "r", "markdown", "rnoweb", "yaml" }):wait(300000)
vim.treesitter.start()

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

local repl = require('ans-repl')
repl.setup("r", "(binary_operator lhs: (_) rhs: (function_definition)) @func")

vim.keymap.set("n", "<localleader>rp", function() repl.send_cword("print(%s)") end, { desc = "Print object under cursor", buffer = 0 })
vim.keymap.set("n", "<localleader>rg", function() repl.send_cword("dplyr::glimpse(%s)") end, { desc = "dplyr::glimpse object under cursor", buffer = 0 })
vim.keymap.set("n", "<localleader>rn", function() repl.send_cword("names(%s)") end, { desc = "`names` of object under cursor", buffer = 0 })
vim.keymap.set("n", "<localleader>rs", function() repl.send_cword("str(%s)") end, { desc = "`str` of object under cursor", buffer = 0 })

vim.keymap.set("i", "<M-.>", " |> ", { desc = "Insert |>", buffer = 0 })
vim.keymap.set("i", "<M-->", " <- ", { desc = "Insert <-", buffer = 0 })
vim.keymap.set("i", "<M-i>", " %in% ", { desc = "Insert '%in%'", buffer = 0 })

vim.keymap.set("n", "<localleader>P", function() repl.send_code("quartz()") end, { desc = "Send plot config" })

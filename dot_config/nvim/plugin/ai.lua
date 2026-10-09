vim.pack.add({
  "https://github.com/coder/claudecode.nvim",
  "https://github.com/folke/snacks.nvim"
})

require('claudecode').setup()

-- Re-showing a hidden Claude split uses an explicit-width `:vsplit`, which
-- skips 'equalalways', so only the adjacent window shrinks. Equalize the other
-- windows like a fresh split does (Claude's split has 'winfixwidth' set).
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = vim.api.nvim_create_augroup("ClaudeEqualize", { clear = true }),
  callback = function(args)
    if args.buf ~= require('claudecode.terminal').get_active_terminal_bufnr() then
      return
    end
    vim.schedule(function() vim.cmd("wincmd =") end)
  end,
})

vim.keymap.set("n", "<leader>ai", "<cmd>ClaudeCode<CR>", { desc = "Toggle Claude" })
vim.keymap.set("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<CR>", { desc = "Add buffer to Claude" })
vim.keymap.set("x", "<leader>as", "<cmd>ClaudeCodeSend<CR>", { desc = "Send selection to Claude" })
vim.keymap.set("x", "<leader>ax", "<cmd>ClaudeCodeSendText /clear<CR>", { desc = "Clear Claude session" })

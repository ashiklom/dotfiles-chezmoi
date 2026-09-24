-- You'll need to include both jet.nvim and jet.ark
vim.pack.add({
  "https://github.com/wurli/jet.nvim",
})

require("jet").setup()

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = vim.api.nvim_create_augroup("ans_jetrepl", { clear = true }),
  callback = function (args)
    if vim.bo[args.buf].filetype == 'jetrepl' then
      local win = vim.fn.bufwinid(args.buf)
      local width = math.min(100, math.floor(vim.o.columns * 0.5))
      vim.api.nvim_win_set_width(win, width)
    end
  end
})

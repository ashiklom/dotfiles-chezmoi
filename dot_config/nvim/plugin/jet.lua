-- You'll need to include both jet.nvim and jet.ark
vim.pack.add({
  "https://github.com/wurli/jet.nvim",
  "https://github.com/wurli/jet.ark",
})

require("jet").setup({})
require("jet.ark").setup({
	ark_binary_path = "~/.local/bin/ark",
})

local toggle_repl = function()
	local ft = vim.bo.filetype
	return function()
		require("jet.api").get_kernel({ filetype = ft }, function(k) k:term_toggle() end)
	end
end

vim.keymap.set("n", "<leader>jp", toggle_repl("python"), { desc = "Open Python (Jet)" })
vim.keymap.set("n", "<leader>jr", toggle_repl("r"), { desc = "Open R (Jet)" })

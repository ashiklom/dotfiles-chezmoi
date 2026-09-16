vim.pack.add({
  'https://github.com/ibhagwan/fzf-lua'
})

-- fzf
local address = vim.fn.stdpath("run") .. "/fzf-lua." .. vim.fn.getpid()
local ok, server = pcall(vim.fn.serverstart, address)
if ok then
  vim.g.fzf_lua_server = server
end

require('fzf-lua').setup({
  keymap = {
    builtin = {
      ["<M-0>"] = "toggle-preview",
      ["<M-=>"] = "toggle-fullscreen",
      ["<M-.>"] = "toggle-preview-cw",
      ["<M-,>"] = "toggle-preview-ccw",
      ["<M-/>"] = "toggle-help",
    }
  },
  winopts = {
    preview = {
      layout = "vertical"
    }
  }
})

-- require('fzf-lua').register_ui_select()

vim.keymap.set('n', "<leader> ", function() require('fzf-lua').files() end, {desc = "Files"})
vim.keymap.set('n', "<leader>/", function() require('fzf-lua').live_grep() end, {desc = "Search project"} )
vim.keymap.set('n', "<leader>,", function() require('fzf-lua').resume() end, {desc = "Resume"} )
vim.keymap.set('n', "<leader>fr", function() require('fzf-lua').oldfiles() end, {desc = "Recent files"})
vim.keymap.set('n', "<leader>bb", function() require('fzf-lua').buffers() end, {desc = "Buffers"})
vim.keymap.set('n', "<leader>sh", function() require('fzf-lua').helptags() end, {desc = "Help tags"})
vim.keymap.set('n', "<leader>sk", function() require('fzf-lua').keymaps() end, {desc = "Keymaps"})
vim.keymap.set('n', '<leader>s"', function() require('fzf-lua').registers() end, {desc = "Registers"})

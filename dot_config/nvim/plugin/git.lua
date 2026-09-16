vim.pack.add({
  'https://github.com/NeogitOrg/neogit',
  'https://github.com/sindrets/diffview.nvim',
  'https://github.com/lewis6991/gitsigns.nvim',
})

-- git
require('neogit').setup({
  disable_commit_confirmation = true,
  mappings = {
    popup = {
      ["F"] = "PullPopup",
      ["p"] = "PushPopup"
    }
  },
})

require('gitsigns').setup()

vim.keymap.set('n', "<leader>gg", function() require('neogit').open() end, {desc = "Neogit"})
vim.keymap.set('n', "]h", function() require('gitsigns').next_hunk() end, {desc = "Next hunk"})
vim.keymap.set('n', "[h", function() require('gitsigns').prev_hunk() end, {desc = "Previous hunk"})
vim.keymap.set('n', "<leader>hh", function() require('gitsigns').preview_hunk() end, {desc = "Preview hunk"})
vim.keymap.set('n', "<leader>hs", function() require('gitsigns').stage_hunk() end, {desc = "Stage hunk"})
vim.keymap.set('n', "<leader>hx", function() require('gitsigns').reset_hunk() end, {desc = "Reset hunk"})
vim.keymap.set('n', "<leader>hz", function() require('gitsigns').undo_stage_hunk() end, {desc = "Undo stage hunk"})
vim.keymap.set('n', "<leader>hb", function() require('gitsigns').blame_line() end, {desc = "Blame line"})

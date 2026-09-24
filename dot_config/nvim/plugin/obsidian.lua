vim.pack.add({
  { src = "https://github.com/obsidian-nvim/obsidian.nvim", version = vim.version.range('*') }
})

require("obsidian").setup({
  legacy_commands = false,
  picker = { name = "fzf-lua" },
  ui = { enable = false },
  note_id_func = require('obsidian.builtin').title_id,
  workspaces = {
    {
      name = "main",
      path = "~/obsidian-notes"
    }
  },
  daily_notes = {
    enabled = true,
    folder = "Daily"
  },
  checkbox = {
    order = { " ", "x" }
  }
})

local function set_obsidian_maps()
  vim.keymap.set('n', '<leader>vv', '<cmd>Obsidian<CR>', { desc = "Obsidian", buffer = true })
  vim.keymap.set('n', '<leader>vd', '<cmd>Obsidian today<CR>', { desc = "Obsidian today", buffer = true })
  vim.keymap.set('n', '<leader>vl', '<cmd>Obsidian today<CR>', { desc = "Obsidian today", buffer = true })
  vim.keymap.set('n', '<leader> ', '<cmd>Obsidian quick_switch<CR>', { desc = "Obsidian quick switch", buffer = true })
  vim.keymap.set('n', '<leader>/', '<cmd>Obsidian search<CR>', { desc = "Obsidian search", buffer = true })
  vim.keymap.set('i', '<C-l>', '<cmd>Obsidian quick_switch<CR>', { desc = "Obsidian quick switch", buffer = true })
end

vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("ans_obsidian", { clear = true }),
  pattern = { "ObsidianWorkspaceSet", "ObsidianNoteEnter" },
  callback = function()
    set_obsidian_maps()
  end
})

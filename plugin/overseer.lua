vim.pack.add({
  'https://github.com/stevearc/overseer.nvim'
})

require('overseer').setup()

vim.keymap.set('n', '<leader>ot', function() require('overseer').toggle() end, {desc = "Overseer toggle"})
vim.keymap.set('n', '<leader>or', function() require('overseer').run_task() end, {desc = "Overseer run"})
local overseer_rerun_or_run = function()
  local ovs = require('overseer')
  local tasks = ovs.list_tasks({recent_first = true})
  if vim.tbl_isempty(tasks) then
    vim.notify("No tasks found")
    ovs.run_task()
    return
  end
  local task = tasks[1]
  ovs.run_action(task, "restart")
end
vim.keymap.set("n", "<leader>oo", overseer_rerun_or_run, {desc = "Overseer rerun"})

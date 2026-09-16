vim.g.mapleader = ' '
vim.g.maplocalleader = ' m'

vim.opt.tabstop = 2
vim.opt.shiftwidth = 0
vim.opt.softtabstop = -1
vim.opt.shiftround = true
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.copyindent = true
vim.opt.wrap = false
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.number = true

vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.scrolloff = 2
vim.opt.swapfile = false
vim.opt.signcolumn = "yes"

vim.opt.completeopt:remove("preview")
vim.opt.listchars = "tab:>-,trail:-,nbsp:+"
-- vim.opt.wildignore:append({'*.o', '*.so', '*.html'})

vim.opt.formatoptions:remove("t")
vim.opt.formatoptions:remove("o")
vim.opt.formatoptions:append("w")

-- Disable mouse
vim.opt.mouse = ''

-- Complete file names after `=`
vim.opt.isfname:remove('=')

-- Stolen from TJ Devries:
-- https://github.com/tjdevries/config.nvim/blob/master/plugin/clipboard.lua
if vim.env.SSH_CONNECTION or vim.env.WSL_VERSION then
  local function vim_paste()
    local content = vim.fn.getreg('"')
    return vim.split(content, "\n")
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*")
    },
    paste = {
      ["+"] = vim_paste,
      ["*"] = vim_paste
    }
  }
end

vim.pack.add({
  -- "https://github.com/folke/which-key.nvim",
  'https://github.com/nvim-mini/mini.icons',
  'https://github.com/stevearc/oil.nvim',
  --
  'https://github.com/stevearc/conform.nvim'
})

require('mini.icons').setup()

require('oil').setup({
  buf_options = {
    buflisted = false,
    bufhidden = "hide"
  },
  cleanup_delay_ms = 2000
})


vim.keymap.set('n', "<leader>fs", vim.cmd.write, {desc = "Save file"})
vim.keymap.set('n', "<leader>fo", function() vim.cmd.edit('.') end, {desc = "Open file directory"})

vim.keymap.set('i', 'jk', '<ESC>', {desc = "Normal mode"})
vim.keymap.set('n', '<ESC>', vim.cmd.nohlsearch)
vim.keymap.set('n', 'z.', 'zszH', {desc = "Center horizontally on character"})
vim.keymap.set('n', 'gb', '<C-^>', {desc = "Most recent buffer"})

vim.keymap.set('n', "<leader>w-", vim.cmd.split, {desc = "Split window down"})
vim.keymap.set('n', "<leader>w\\", vim.cmd.vsplit, {desc = "Split window down"})
vim.keymap.set('n', "<leader>wd", vim.cmd.close, {desc = "Split window down"})
vim.keymap.set('n', "<leader>wj", function() vim.cmd.wincmd("j") end, {desc = "Goto window below"})
vim.keymap.set('n', "<leader>wk", function() vim.cmd.wincmd("k") end, {desc = "Goto window above"})
vim.keymap.set('n', "<leader>wh", function() vim.cmd.wincmd("h") end, {desc = "Goto window left"})
vim.keymap.set('n', "<leader>wl", function() vim.cmd.wincmd("l") end, {desc = "Goto window right"})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("spelling", { clear = true }),
  pattern = {
    "gitcommit",
    "markdown",
    "org",
    "plaintex",
    "quarto",
    "tex",
    "text",
  },
  command = "setlocal spell wrap"
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup('close_with_q', { clear = true }),
  pattern = {
    "help",
    "lspinfo",
    "notify",
    "qf",
    "checkhealth",
    "grug-far",
    "nvim-pack"
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", {
      buffer = event.buf,
      silent = true,
      desc = "Quit buffer"
    })
  end
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup('bufdelete_with_q', { clear = true }),
  pattern = {
    "oil"
  },
  callback = function(event)
    vim.keymap.set("n", "q", function() MiniBufremove.delete() end, {
      buffer = event.buf,
      silent = true,
      desc = "Quit buffer"
    })
  end
})

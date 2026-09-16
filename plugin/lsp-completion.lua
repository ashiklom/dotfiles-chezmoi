vim.pack.add({
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/neovim/nvim-lspconfig',
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('v1.*') },
  -- 'https://github.com/jmbuhr/cmp-pandoc-references',
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("ansauto_lsp", {clear = true}),
  callback = function (_)
    vim.diagnostic.config({ virtual_text = true })
  end
})

vim.keymap.set("n", "<leader>gz", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
  local diag_status = vim.diagnostic.is_enabled() and "enabled" or "disabled"
  vim.notify("LSP diagnostics " .. diag_status)
end, {})

vim.keymap.set('n', '<leader>?', vim.diagnostic.open_float, {desc = "Current diagnostic"})

require('blink.cmp').setup({
  keymap = {
    preset = "super-tab",
    ['<C-space>'] = { function(cmp) cmp.show() end},
    ['<C-s>'] = { 'show_signature', 'hide_signature', 'fallback' },
    ['<C-k>'] = false
  },
  completion = {
    menu = {
      auto_show = function()
        return not vim.tbl_contains({"markdown", "quarto", "text"}, vim.bo.filetype)
      end
    },
    list = {
      selection = {
        preselect = function (_)
          -- Prevents accidental completions while navigating a snippet
          return not require('blink.cmp').snippet_active({ direction = 1 })
        end
      }
    }
  },
  sources = {
    -- per_filetype = {
    --   quarto = { inherit_defaults = true, 'references' },
    --   lua = {  inherit_defaults = true, 'lazydev' }
    -- },
    providers = {
      -- path = {
      --   opts = {
      --     get_cwd = function (_)
      --       return vim.fn.getcwd()
      --     end
      --   }
      -- },
      -- references = {
      --   name = "pandoc_references",
      --   module = "cmp-pandoc-references.blink"
      -- },
    }
  },
  signature = {
    enabled = true,
    trigger = {
      enabled = false
    }
  }
})

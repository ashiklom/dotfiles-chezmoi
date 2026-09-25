require('nvim-treesitter').install({"lua"})

vim.lsp.config("lua_ls", {
  settings = { Lua = { diagnostics = { globals = {"vim", "MiniBufremove", "Snacks"}  } } }
})

vim.lsp.enable({ "lua_ls" })

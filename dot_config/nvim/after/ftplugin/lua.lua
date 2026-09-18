require('nvim-treesitter').install({"lua"})

vim.lsp.config("lua_ls", {
  settings = { Lua = { diagnostics = { globals = {"vim", "MiniBufremove"}  } } }
})

vim.lsp.enable({ "lua_ls" })

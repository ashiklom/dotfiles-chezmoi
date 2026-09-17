require('nvim-treesitter').install({ "python" })

vim.lsp.config("ruff", {
  on_attach = function(client, _)
    client.server_capabilities.hoverProvider = false
  end
})

vim.lsp.enable({"ty", "ruff"})

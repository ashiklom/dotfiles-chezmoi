require('nvim-treesitter').install({ "python" })

vim.lsp.config("ruff", {
  on_attach = function(client, _)
    client.server_capabilities.hoverProvider = false
  end
})

local uv_script = require('ans-uv-script')

-- uv scripts get a separate ty client using the script's environment
vim.lsp.config("ty", { root_dir = uv_script.ty_root_dir })

vim.lsp.enable({"ty", "ruff"})

uv_script.attach(0)

if not vim.g.ans_jet_ipy_setup then
  vim.pack.add({
    "https://github.com/wurli/jet.ipy"
  })
  require('jet.ipy').setup()
  vim.g.ans_jet_ipy_setup = true
end

local api = require('jet.api')
local repl = require('ans-repl')

repl.setup("python", "(function_definition) @func", {
  -- uv scripts use the kernel for the script's environment (started if needed)
  buf_kernel = function(start, callback)
    if not uv_script.metadata(0) then
      return false
    end
    local script = vim.b.uv_script
    if not script then
      vim.notify("uv script environment isn't ready yet", vim.log.levels.WARN)
      return true
    end
    local k = api.list_kernels({ spec_path = script.spec_path, status = { "connected", "connecting" } })[1]
    if not k and start then
      k = require('jet.core.kernel').init_owned({ spec_path = script.spec_path })
    end
    if k then
      callback(k)
    end
    return true
  end,
})

vim.keymap.set("n", "<localleader>rp", function() repl.send_cword("print(%s)") end, { desc = "Print object under cursor", buffer = 0 })
vim.keymap.set("n", "<localleader>P", function() repl.send_code("%matplotlib macosx") end, { desc = "Send plot config" })
vim.keymap.set("n", "<localleader>q", function() repl.send_code("plt.close()") end, { desc = "Close current plot" })

-- Support for PEP 723 scripts (inline `# /// script` metadata) run with uv.
-- Each script gets its own ty client and Jupyter kernelspec pointing at the
-- environment uv creates for it (`uv sync --script`).
local M = {}

---Return the buffer's inline script metadata block, if it has one
---@param buf integer
---@return string?
function M.metadata(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local start
  for i, line in ipairs(lines) do
    if not start then
      if line:match("^# /// script%s*$") then
        start = i
      end
    elseif line:match("^# ///%s*$") then
      return table.concat(lines, "\n", start, i)
    elseif not line:match("^#") then
      return nil
    end
  end
end

---Write a kernelspec that runs ipykernel in the script's environment.
---ipykernel is layered on with `uv run --with`, so the script environment
---itself isn't modified (and `uv sync --script` won't remove it).
---@return string spec_path
local function write_kernelspec(file, python, env)
  local dir = vim.fs.joinpath(vim.fn.stdpath("cache"), "uv-script-kernels", vim.fs.basename(env))
  vim.fn.mkdir(dir, "p")
  local spec_path = vim.fs.joinpath(dir, "kernel.json")
  local spec = {
    argv = {
      vim.fn.exepath("uv"), "run", "--no-project", "--python", python, "--with", "ipykernel",
      "python", "-m", "ipykernel_launcher", "-f", "{connection_file}",
    },
    display_name = "Python (" .. vim.fs.basename(file) .. ")",
    language = "python",
  }
  vim.fn.writefile({ vim.json.encode(spec) }, spec_path)
  return spec_path
end

---Attach a ty client that uses the script's environment, replacing any other
---ty client attached to the buffer. A new client is started whenever the
---metadata changes so ty picks up the new dependencies.
local function start_ty(buf, env, meta)
  local base = vim.lsp.config.ty
  local file = vim.api.nvim_buf_get_name(buf)
  local config = vim.tbl_extend("force", base, {
    name = "ty-script",
    root_dir = vim.fs.root(buf, base.root_markers) or vim.fs.dirname(file),
    cmd_env = { VIRTUAL_ENV = env },
    uv_script_metadata = meta,
  })

  local old = vim.list_extend(
    vim.lsp.get_clients({ bufnr = buf, name = "ty" }),
    vim.lsp.get_clients({ bufnr = buf, name = "ty-script" })
  )

  local id = vim.lsp.start(config, {
    bufnr = buf,
    reuse_client = function(client, c)
      return client.name == c.name
        and client.root_dir == c.root_dir
        and client.config.cmd_env.VIRTUAL_ENV == c.cmd_env.VIRTUAL_ENV
        and client.config.uv_script_metadata == c.uv_script_metadata
    end,
  })

  for _, client in ipairs(old) do
    if client.id ~= id then
      vim.lsp.buf_detach_client(buf, client.id)
      if vim.tbl_isempty(client.attached_buffers) then
        client:stop()
      end
    end
  end
end

---Resolve (creating if needed) the script's environment, then set
---`vim.b[buf].uv_script` and attach ty. Does nothing for non-script buffers.
---@param buf integer
function M.setup(buf)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  local meta = M.metadata(buf)
  local file = vim.api.nvim_buf_get_name(buf)
  if not meta or not vim.uv.fs_stat(file) then
    return
  end

  local on_err = function(cmd, res)
    vim.schedule(function()
      vim.notify(("`uv %s` failed for %s:\n%s"):format(cmd, vim.fs.basename(file), res.stderr), vim.log.levels.ERROR)
    end)
  end

  vim.system({ "uv", "sync", "--script", file }, { text = true }, function(sync)
    if sync.code ~= 0 then
      return on_err("sync --script", sync)
    end
    vim.system({ "uv", "python", "find", "--script", file }, { text = true }, function(find)
      if find.code ~= 0 then
        return on_err("python find --script", find)
      end
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        local python = vim.trim(find.stdout)
        local env = vim.fs.dirname(vim.fs.dirname(python))
        vim.b[buf].uv_script = {
          python = python,
          env = env,
          metadata = meta,
          spec_path = write_kernelspec(file, python, env),
        }
        start_ty(buf, env, meta)
      end)
    end)
  end)
end

---Set up a python buffer: resolve its script environment now, and again
---whenever the metadata changes on write.
---@param buf integer
function M.attach(buf)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  M.setup(buf)
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("ans_uv_script_" .. buf, { clear = true }),
    buffer = buf,
    callback = function()
      local info = vim.b[buf].uv_script
      if M.metadata(buf) ~= (info and info.metadata) then
        M.setup(buf)
      end
    end,
  })
end

---ty's normal root_dir resolution, but skipping uv scripts (which get their
---own client from `start_ty()`).
function M.ty_root_dir(buf, on_dir)
  if not M.metadata(buf) then
    on_dir(vim.fs.root(buf, vim.lsp.config.ty.root_markers))
  end
end

return M

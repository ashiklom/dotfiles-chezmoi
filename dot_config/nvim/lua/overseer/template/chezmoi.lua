return {
  name = "chezmoi",
  condition = {
    dir = vim.fn.expand("~/.local/share/chezmoi")
  },
  generator = function(search)
    if vim.fn.executable("chezmoi") == 0 then
      return "Command 'chezmoi' not found"
    end

    return {
      {
        name = "apply",
        builder = function() return { cmd = { "chezmoi" }, args = { "apply" } } end
      },
      {
        name = "apply init recursive",
        builder = function() return { cmd = { "chezmoi" }, args = { "apply", "--init", "-R" } } end
      }
    }
  end
}

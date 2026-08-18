-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Global sharp border style ('single' for ┌─┐│└─┘ sharp box corners)
vim.g.border = "single"

-- Configure LSP diagnostic float borders to sharp
vim.diagnostic.config({
  float = { border = "single" },
})

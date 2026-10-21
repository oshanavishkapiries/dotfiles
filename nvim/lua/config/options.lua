-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Global sharp border style ('single' for ┌─┐│└─┘ sharp box corners)
vim.g.border = "single"

-- Configure LSP diagnostic float borders to sharp
vim.diagnostic.config({
  float = { border = "single" },
})

-- Use zsh for Neovim built-in terminal
vim.opt.shell = "zsh"

-- Enable OSC 52 clipboard provider when running over SSH
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION or vim.env.SSH_CLIENT then
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = osc52.paste("+"),
      ["*"] = osc52.paste("*"),
    },
  }
end

-- Editing comfort
vim.opt.scrolloff = 8 -- keep context lines around the cursor
vim.opt.updatetime = 200 -- faster CursorHold / gitsigns blame

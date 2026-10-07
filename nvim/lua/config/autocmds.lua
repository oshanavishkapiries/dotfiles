-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- Automatically sync Neovim config files to dotfiles repo whenever saved
vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("AutoSyncDotfiles", { clear = true }),
  pattern = vim.fn.stdpath("config") .. "/*",
  callback = function()
    local config_dir = vim.fn.stdpath("config") .. "/"
    local dotfiles_dir = "/home/oshan/Projects/dotfiles/nvim/"
    vim.fn.jobstart({ "rsync", "-a", "--exclude=.git*", config_dir, dotfiles_dir })
  end,
})

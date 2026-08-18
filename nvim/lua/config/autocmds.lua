-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Force every remaining UI surface transparent (covers what tokyonight's
-- `transparent` option and `styles.floats/sidebars` don't already clear)
local function clear_bg()
  local groups = {
    "Normal",
    "NormalNC",
    "NormalFloat",
    "FloatBorder",
    "FloatTitle",
    "SignColumn",
    "LineNr",
    "CursorLineNr",
    "EndOfBuffer",
    "WinSeparator",
    "VertSplit",
    "Pmenu",
    "PmenuSel",
    "TabLine",
    "TabLineFill",
    "StatusLine",
    "StatusLineNC",
    "WhichKeyFloat",
    "TelescopeNormal",
    "TelescopeBorder",
    "NoiceCmdline",
    "NoiceCmdlinePopup",
  }
  for _, group in ipairs(groups) do
    vim.api.nvim_set_hl(0, group, { bg = "none" })
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("transparent_bg", { clear = true }),
  callback = clear_bg,
})

clear_bg()

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


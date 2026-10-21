return {
  -- Catppuccin Mocha with transparent background
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      float = { transparent = true, solid = false },
      term_colors = true,
      integrations = {
        blink_cmp = true,
        neotree = true,
        snacks = true,
        which_key = true,
        noice = true,
        telescope = { enabled = true },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },
}

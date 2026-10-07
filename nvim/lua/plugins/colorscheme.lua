return {
  -- Ayu Dark colorscheme with sleek dark matte background
  {
    "Shatur/neovim-ayu",
    name = "ayu",
    lazy = false,
    priority = 1000,
    opts = {
      mirage = false, -- false for classic Ayu Dark matte background
      overrides = {},
    },
    config = function(_, opts)
      local ayu = require("ayu")
      ayu.setup(opts)
      ayu.colorscheme()
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "ayu-dark",
    },
  },
}

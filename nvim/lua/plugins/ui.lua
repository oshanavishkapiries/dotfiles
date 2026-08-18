return {
  -- Mason UI sharp border
  {
    "mason-org/mason.nvim",
    opts = {
      ui = {
        border = "single",
      },
    },
  },

  -- Which-key UI sharp border
  {
    "folke/which-key.nvim",
    opts = {
      win = {
        border = "single",
      },
    },
  },

  -- Noice floating windows & popups sharp border
  {
    "folke/noice.nvim",
    opts = {
      views = {
        cmdline_popup = {
          border = {
            style = "single",
          },
        },
        popupmenu = {
          border = {
            style = "single",
          },
        },
        hover = {
          border = {
            style = "single",
          },
        },
      },
    },
  },

  -- Snacks floating windows sharp border
  {
    "folke/snacks.nvim",
    opts = {
      styles = {
        float = {
          border = "single",
        },
        notification = {
          border = "single",
        },
      },
    },
  },

  -- Telescope pickers sharp border
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
      },
    },
  },

  -- Neo-tree popups sharp border
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      popup_border_style = "single",
    },
  },
}

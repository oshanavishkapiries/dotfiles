return {
  -- Inline git blame on the current line
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = { delay = 500 },
    },
  },

  -- Side-by-side diffs and file history (lazy: only loads on command/key)
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview: open" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Diffview: close" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: file history" },
    },
    opts = {},
  },

  -- TODO comments list (LazyVim already has <leader>xt / <leader>st)
  {
    "folke/todo-comments.nvim",
    event = "LazyFile",
    opts = {},
  },
}

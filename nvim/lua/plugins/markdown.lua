return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install && rm -f bin/markdown-preview-*",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {},
    keys = {
      {
        "<leader>mp",
        function()
          local file = vim.fn.expand("%:p")
          local Terminal = require("toggleterm.terminal").Terminal
          local glow = Terminal:new({
            cmd = "glow " .. vim.fn.shellescape(file),
            direction = "float",
            close_on_exit = false,
          })
          glow:toggle()
        end,
        ft = "markdown",
        desc = "Preview markdown with glow",
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          prepend_args = { "--config", vim.fn.stdpath("config") .. "/.markdownlint.jsonc" },
        },
      },
    },
  },
}

-- oil.nvim: edit directories (local or over SSH) like a buffer.
-- Remote host comes from ~/.ssh/config (Host LAB1).
local remote = "oil-ssh://LAB1/"

return {
  {
    "stevearc/oil.nvim",
    lazy = false, -- needed so `nvim oil-ssh://...` and :e oil-ssh://... work
    dependencies = { "nvim-mini/mini.icons" },
    opts = {
      default_file_explorer = false, -- keep neo-tree / snacks explorer as the default
      delete_to_trash = false,
      skip_confirm_for_simple_edits = false,
      view_options = { show_hidden = true },
      -- LAB1 defines LocalForward ports; don't try to bind them for every scp/ssh call
      extra_scp_args = { "-o", "ClearAllForwardings=yes" },
      keymaps = {
        ["q"] = "actions.close",
        ["<C-s>"] = false, -- keep default save mapping free
      },
    },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Oil: parent directory (local)" },
      { "<leader>ol", "<cmd>Oil<cr>", desc = "Oil: local" },
      { "<leader>or", "<cmd>Oil " .. remote .. "<cr>", desc = "Oil: remote LAB1 home" },
      {
        "<leader>oR",
        function()
          vim.ui.input({ prompt = "Remote path: ", default = "~/" }, function(path)
            if path and path ~= "" then
              path = path:gsub("^~/?", "")
              vim.cmd("Oil " .. remote .. "/" .. path)
            end
          end)
        end,
        desc = "Oil: remote LAB1 (choose path)",
      },
    },
  },
}

return {
  {
    "nvim-mini/mini.starter",
    opts = function(_, opts)
      local starter = require("mini.starter")

      local code_logo = {
        "  ██████╗   ██████╗  ",
        "  ██╔═══╝   ╚═══██║  ",
        "  ██║           ██║  ",
        "  ██║           ██║  ",
        "  ██████╗   ██████║  ",
        "  ╚═════╝   ╚═════╝  ",
      }

      vim.api.nvim_set_hl(0, "MiniStarterHeader", { bold = true })
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          vim.api.nvim_set_hl(0, "MiniStarterHeader", { bold = true })
        end,
      })

      -- Custom content hook to center ONLY the logo and place cursor anchor at bottom right
      local function center_logo_bottom_right(content, buf_id)
        local win_id = vim.fn.bufwinid(buf_id or 0)
        if win_id < 0 then
          win_id = vim.api.nvim_get_current_win()
        end

        local header_lines = {}
        for _, line in ipairs(content) do
          if type(line) == "table" and #line > 0 and line[1].type == "header" then
            table.insert(header_lines, line)
          end
        end

        if #header_lines == 0 then
          header_lines = content
        end

        -- Calculate max visual display width of ONLY the header/logo lines
        local max_w = 0
        for _, line in ipairs(header_lines) do
          local line_str = ""
          for _, unit in ipairs(line) do
            line_str = line_str .. (unit.string or "")
          end
          local w = vim.fn.strdisplaywidth(line_str)
          if w > max_w then
            max_w = w
          end
        end

        local win_w = vim.api.nvim_win_get_width(win_id)
        local win_h = vim.api.nvim_win_get_height(win_id)

        local left_pad = math.max(0, math.floor(0.5 * (win_w - max_w)))
        local top_pad = math.max(0, math.floor(0.5 * (win_h - #header_lines)))

        local result = {}
        -- Top padding
        for _ = 1, top_pad do
          table.insert(result, { { string = "", type = "empty" } })
        end

        -- Padded logo header lines
        local pad_str = string.rep(" ", left_pad)
        for _, line in ipairs(header_lines) do
          local new_line = vim.deepcopy(line)
          if #new_line > 0 then
            new_line[1].string = pad_str .. (new_line[1].string or "")
          end
          table.insert(result, new_line)
        end

        -- Pad empty lines down to bottom of window (win_h - 1)
        local current_lines = #result
        for _ = current_lines + 1, win_h - 1 do
          table.insert(result, { { string = "", type = "empty" } })
        end

        -- Bottom-right item line so the cursor is placed in the bottom right corner
        local bottom_spaces = string.rep(" ", math.max(0, win_w - 1))
        table.insert(result, {
          {
            string = bottom_spaces,
            type = "item",
            item = { name = " ", action = "", section = "" },
          },
        })

        return result
      end

      -- Responsive auto-recenter on terminal resize, window resize, or buffer enter
      local function refresh_starters()
        for _, win_id in ipairs(vim.api.nvim_list_wins()) do
          local buf_id = vim.api.nvim_win_get_buf(win_id)
          if vim.api.nvim_buf_is_valid(buf_id) and vim.bo[buf_id].filetype == "ministarter" then
            starter.refresh(buf_id)
          end
        end
      end

      vim.api.nvim_create_autocmd({ "VimResized", "WinResized", "BufEnter", "BufWinEnter" }, {
        callback = refresh_starters,
      })

      -- Position cursor in bottom-right corner when mini.starter opens
      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniStarterOpened",
        callback = function(ev)
          vim.schedule(function()
            local win_id = vim.fn.bufwinid(ev.buf)
            if win_id < 0 then
              win_id = 0
            end
            local buf_id = vim.api.nvim_win_get_buf(win_id)
            local line_count = vim.api.nvim_buf_line_count(buf_id)
            local last_lines = vim.api.nvim_buf_get_lines(buf_id, line_count - 1, line_count, false)
            local last_len = (last_lines and #last_lines > 0) and #last_lines[1] or 0
            pcall(vim.api.nvim_win_set_cursor, win_id, { line_count, math.max(0, last_len - 1) })
          end)
        end,
      })

      opts.evaluate_single = true
      opts.items = { { name = " ", action = "", section = "" } }
      opts.footer = function()
        return ""
      end
      opts.query_updator = function()
        return ""
      end

      opts.content_hooks = {
        center_logo_bottom_right,
      }

      opts.header = function()
        return table.concat(code_logo, "\n")
      end
    end,
  },
}

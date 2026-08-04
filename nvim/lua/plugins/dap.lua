-- =============================================================================
--  DAP (Debug Adapter Protocol) - Full Setup
--  Languages: Go, Python, Java, JavaScript, TypeScript
-- =============================================================================

return {

  -- ─── Core DAP Engine ────────────────────────────────────────────────────────
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      "leoluz/nvim-dap-go",
      "mfussenegger/nvim-dap-python",
    },
    keys = {
      -- ── Start / Continue ──────────────────────────────────────────────────
      { "<F5>",        function() require("dap").continue() end,           desc = "DAP: Start / Continue" },
      { "<F10>",       function() require("dap").step_over() end,          desc = "DAP: Step Over" },
      { "<F11>",       function() require("dap").step_into() end,          desc = "DAP: Step Into" },
      { "<F12>",       function() require("dap").step_out() end,           desc = "DAP: Step Out" },
      -- ── Breakpoints ───────────────────────────────────────────────────────
      { "<leader>db",  function() require("dap").toggle_breakpoint() end,  desc = "DAP: Toggle Breakpoint" },
      { "<leader>dB",  function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,                                                                desc = "DAP: Conditional Breakpoint" },
      { "<leader>dl",  function()
          require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point: "))
        end,                                                                desc = "DAP: Log Point" },
      -- ── Session ───────────────────────────────────────────────────────────
      { "<leader>dr",  function() require("dap").repl.open() end,          desc = "DAP: Open REPL" },
      { "<leader>dR",  function() require("dap").run_last() end,           desc = "DAP: Run Last" },
      { "<leader>dx",  function() require("dap").terminate() end,          desc = "DAP: Terminate" },
      -- ── UI ────────────────────────────────────────────────────────────────
      { "<leader>du",  function() require("dapui").toggle() end,           desc = "DAP: Toggle UI" },
      { "<leader>de",  function() require("dapui").eval() end,             desc = "DAP: Eval Expression", mode = { "n", "v" } },
      -- ── Go ────────────────────────────────────────────────────────────────
      { "<leader>dgt", function() require("dap-go").debug_test() end,      desc = "DAP Go: Debug Test" },
      { "<leader>dgT", function() require("dap-go").debug_last_test() end, desc = "DAP Go: Debug Last Test" },
      -- ── Python ────────────────────────────────────────────────────────────
      { "<leader>dpt", function() require("dap-python").test_method() end, desc = "DAP Python: Test Method" },
      { "<leader>dpc", function() require("dap-python").test_class() end,  desc = "DAP Python: Test Class" },
    },
    config = function()
      local dap = require("dap")

      -- ── Icons ───────────────────────────────────────────────────────────────
      vim.fn.sign_define("DapBreakpoint",          { text = "●", texthl = "DapBreakpoint",          linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◉", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint",            { text = "◆", texthl = "DapLogPoint",            linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped",             { text = "▶", texthl = "DapStopped",             linehl = "DapStoppedLine", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected",  { text = "✗", texthl = "DapBreakpointRejected",  linehl = "", numhl = "" })

      -- ── Auto open/close UI (dapui is already loaded as dependency) ──────────
      local ok, dapui = pcall(require, "dapui")
      if ok then
        dap.listeners.after.event_initialized["dapui_config"]  = function() dapui.open() end
        dap.listeners.before.event_terminated["dapui_config"]  = function() dapui.close() end
        dap.listeners.before.event_exited["dapui_config"]      = function() dapui.close() end
      end

      -- ══════════════════════════════════════════════════════════════════════
      --  GO  (Delve)
      -- ══════════════════════════════════════════════════════════════════════
      require("dap-go").setup({
        delve = {
          path                 = "dlv",
          initialize_timeout_sec = 20,
          port                 = "${port}",
          args                 = {},
          build_flags          = {},
          detached             = vim.fn.has("win32") == 0,
        },
        tests = { verbose = false },
      })

      -- ══════════════════════════════════════════════════════════════════════
      --  PYTHON  (debugpy via Mason)
      -- ══════════════════════════════════════════════════════════════════════
      local debugpy = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
      require("dap-python").setup(debugpy)
      require("dap-python").test_runner = "pytest"

      -- ══════════════════════════════════════════════════════════════════════
      --  JAVASCRIPT & TYPESCRIPT  (vscode-js-debug via Mason)
      -- ══════════════════════════════════════════════════════════════════════
      local js_debug = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter"

      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args    = { js_debug .. "/js-debug/src/dapDebugServer.js", "${port}" },
        },
      }
      dap.adapters["pwa-chrome"] = dap.adapters["pwa-node"]

      for _, lang in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
        dap.configurations[lang] = {
          {
            type    = "pwa-node",
            request = "launch",
            name    = "Launch file (Node)",
            program = "${file}",
            cwd     = "${workspaceFolder}",
            sourceMaps = true,
          },
          {
            type      = "pwa-node",
            request   = "attach",
            name      = "Attach to process (Node)",
            processId = require("dap.utils").pick_process,
            cwd       = "${workspaceFolder}",
            sourceMaps = true,
          },
          {
            type    = "pwa-chrome",
            request = "launch",
            name    = "Launch Chrome (browser)",
            url     = "http://localhost:3000",
            webRoot = "${workspaceFolder}",
            sourceMaps = true,
          },
        }
      end

      -- ══════════════════════════════════════════════════════════════════════
      --  JAVA  (nvim-jdtls handles DAP automatically - no config needed)
      -- ══════════════════════════════════════════════════════════════════════
    end,
  },

  -- ─── DAP UI ─────────────────────────────────────────────────────────────────
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    -- config is handled by nvim-dap above via listeners
    opts = {
      icons = { expanded = "", collapsed = "", current_frame = "" },
      layouts = {
        {
          elements = {
            { id = "scopes",      size = 0.40 },
            { id = "breakpoints", size = 0.20 },
            { id = "stacks",      size = 0.20 },
            { id = "watches",     size = 0.20 },
          },
          size     = 40,
          position = "left",
        },
        {
          elements = {
            { id = "repl",    size = 0.5 },
            { id = "console", size = 0.5 },
          },
          size     = 12,
          position = "bottom",
        },
      },
      floating = { max_height = 0.9, max_width = 0.8, border = "rounded" },
    },
  },

  -- ─── Virtual Text (inline variable values while debugging) ──────────────────
  {
    "theHamsta/nvim-dap-virtual-text",
    opts = {
      enabled                   = true,
      highlight_changed_variables = true,
      show_stop_reason          = true,
      virt_text_pos             = "eol",
    },
  },

  -- ─── Mason: auto-install DAP adapters ───────────────────────────────────────
  -- NOTE: mason.nvim was renamed from williamboman/mason.nvim → mason-org/mason.nvim
  -- LazyVim handles the rename automatically; we just extend ensure_installed.
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "delve",            -- Go
        "debugpy",          -- Python
        "js-debug-adapter", -- JS / TS
      })
      local unique = {}
      local dedup = {}
      for _, tool in ipairs(opts.ensure_installed) do
        if not unique[tool] then
          unique[tool] = true
          table.insert(dedup, tool)
        end
      end
      opts.ensure_installed = dedup
    end,
  },
}

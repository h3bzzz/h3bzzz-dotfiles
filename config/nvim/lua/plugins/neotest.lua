-- neotest: unified in-editor test runner + UI.
-- Adapters: Go, Python, Zig, and Rust (via rustaceanvim).
-- Keymaps live under <leader>T (Terminal already owns <leader>t).
return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- language adapters
      "fredrikaverpil/neotest-golang",
      "nvim-neotest/neotest-python",
      "lawrence-laz/neotest-zig",
    },
    keys = {
      { "<leader>Tt", function() require("neotest").run.run() end, desc = "Run nearest test" },
      { "<leader>TT", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file tests" },
      { "<leader>Ts", function() require("neotest").summary.toggle() end, desc = "Toggle summary" },
      { "<leader>To", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show output" },
      { "<leader>TO", function() require("neotest").output_panel.toggle() end, desc = "Toggle output panel" },
      { "<leader>Tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle watch" },
      { "<leader>Td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest test" },
    },
    config = function()
      local adapters = {
        require("neotest-golang")({
          dap_go_enabled = true,
        }),
        require("neotest-python")({
          dap = { justMyCode = false },
        }),
        require("neotest-zig"),
      }

      -- Rust adapter is provided by rustaceanvim (lang.rust extra), if present.
      local ok, rust_adapter = pcall(require, "rustaceanvim.neotest")
      if ok then
        table.insert(adapters, rust_adapter)
      end

      require("neotest").setup({
        adapters = adapters,
        status = { virtual_text = true },
        output = { open_on_run = false },
      })
    end,
  },
}

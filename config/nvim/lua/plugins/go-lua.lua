-- ~/.config/nvim/lua/plugins/go.lua
return {
  {
    "ray-x/go.nvim",
    dependencies = {
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    ft = { "go", "gomod", "gowork", "gosum" },
    build = ':lua require("go.install").update_all_sync()',
    config = function()
      require("go").setup({
        -- Formatter settings
        gofmt = "gofumpt",
        max_line_len = 120,
        
        -- LSP configuration (integrated with nvim-lspconfig)
        lsp_cfg = false, -- Use our own gopls config from mason-lspconfig-treesitter.lua
        lsp_gofumpt = true,
        lsp_on_attach = function(client, bufnr)
          -- Use default LSP on_attach from LazyVim
        end,
        
        -- DAP debugging
        dap_debug = true,
        dap_debug_keymap = false, -- We'll set our own keymaps
        dap_debug_vt = true,
        dap_debug_gui = true,
        
        -- Testing
        test_runner = "go",
        run_in_floaterm = true,
        
        -- Tools
        trouble = true,
        luasnip = true,
        
        -- Icons
        icons = { breakpoint = "🛑", currentpos = "👉" },
      })
      
      -- Go-specific keymaps (under <leader>G to avoid colliding with Git <leader>g)
      vim.keymap.set("n", "<leader>Gt", "<cmd>GoTest<CR>", { desc = "Go test" })
      vim.keymap.set("n", "<leader>GT", "<cmd>GoTestFunc<CR>", { desc = "Go test function" })
      vim.keymap.set("n", "<leader>Gr", "<cmd>GoRun<CR>", { desc = "Go run" })
      vim.keymap.set("n", "<leader>Gb", "<cmd>GoBuild<CR>", { desc = "Go build" })
      vim.keymap.set("n", "<leader>Gi", "<cmd>GoImports<CR>", { desc = "Go imports" })
      vim.keymap.set("n", "<leader>Gf", "<cmd>GoFmt<CR>", { desc = "Go format" })
      vim.keymap.set("n", "<leader>Gc", "<cmd>GoCoverage<CR>", { desc = "Go coverage" })
      vim.keymap.set("n", "<leader>Gd", "<cmd>GoDoc<CR>", { desc = "Go doc" })
      vim.keymap.set("n", "<leader>Ge", "<cmd>GoIfErr<CR>", { desc = "Go add if err" })
      vim.keymap.set("n", "<leader>Gs", "<cmd>GoFillStruct<CR>", { desc = "Go fill struct" })
      vim.keymap.set("n", "<leader>Gw", "<cmd>GoFillSwitch<CR>", { desc = "Go fill switch" })
    end,
  },
  
  -- Go debugging with DAP
  {
    "leoluz/nvim-dap-go",
    ft = { "go", "gomod" },
    dependencies = "mfussenegger/nvim-dap",
    config = function()
      require("dap-go").setup({
        delve = {
          path = "dlv",
          initialize_timeout_sec = 20,
          port = "${port}",
          args = {},
          build_flags = "",
          detached = vim.fn.has("win32") == 0,
          cwd = nil,
        },
        tests = {
          verbose = false,
        },
      })
      
      -- Go debugging keymaps
      vim.keymap.set("n", "<leader>db", "<cmd>DapToggleBreakpoint<CR>", { desc = "Toggle breakpoint" })
      vim.keymap.set("n", "<leader>dc", "<cmd>DapContinue<CR>", { desc = "Debug continue" })
      vim.keymap.set("n", "<leader>di", "<cmd>DapStepInto<CR>", { desc = "Debug step into" })
      vim.keymap.set("n", "<leader>do", "<cmd>DapStepOver<CR>", { desc = "Debug step over" })
      vim.keymap.set("n", "<leader>dO", "<cmd>DapStepOut<CR>", { desc = "Debug step out" })
      vim.keymap.set("n", "<leader>dr", "<cmd>DapToggleRepl<CR>", { desc = "Debug REPL" })
      vim.keymap.set("n", "<leader>du", "<cmd>DapUI<CR>", { desc = "Debug UI" })
      vim.keymap.set("n", "<leader>dgt", function() require("dap-go").debug_test() end, { desc = "Debug go test" })
      vim.keymap.set("n", "<leader>dgl", function() require("dap-go").debug_last() end, { desc = "Debug last go test" })
    end,
  },
}



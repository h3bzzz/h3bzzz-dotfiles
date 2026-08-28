-- Consolidated AI plugins configuration
return {
  -- Amp AI (Sourcegraph)
  {
    "sourcegraph/amp.nvim",
    branch = "main",
    lazy = false,
    opts = {
      auto_start = true,
      log_level = "info",
    },
    config = function()
      require("amp").setup({
        auto_start = true,
        log_level = "info",
      })

      -- Amp commands
      vim.api.nvim_create_user_command("AmpSend", function(opts)
        local msg = opts.args
        if msg == "" then
          print("Provide a message to send")
          return
        end
        require("amp.message").send_message(msg)
      end, {
        nargs = "*",
        desc = "Send a message to the Amp agent",
      })

      vim.api.nvim_create_user_command("AmpSendBuffer", function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        require("amp.message").send_message(table.concat(lines, "\n"))
      end, {
        desc = "Send the current buffer to the Amp agent",
      })

      vim.api.nvim_create_user_command("AmpPromptSelection", function(opts)
        local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
        require("amp.message").send_to_prompt(table.concat(lines, "\n"))
      end, {
        range = true,
        desc = "Send visual selection to Amp prompt",
      })

      vim.api.nvim_create_user_command("AmpPromptRef", function(opts)
        local bufname = vim.api.nvim_buf_get_name(0)
        if bufname == "" then
          print("Current buffer has no filename")
          return
        end

        local rel = vim.fn.fnamemodify(bufname, ":.")
        local ref = "@" .. rel
        if opts.line1 ~= opts.line2 then
          ref = ref .. "#L" .. opts.line1 .. "-" .. opts.line2
        elseif opts.line1 > 1 then
          ref = ref .. "#L" .. opts.line1
        end

        require("amp.message").send_to_prompt(ref)
      end, {
        range = true,
        desc = "Send file reference (with selection) to Amp prompt",
      })

      -- Amp keymaps under <leader>a (AI group)
      local map = vim.keymap.set
      local opts_n = { noremap = true, silent = true }

      map("n", "<leader>as", ":AmpSend ", vim.tbl_extend("force", opts_n, { desc = "Amp send message" }))
      map("n", "<leader>ab", "<cmd>AmpSendBuffer<CR>", vim.tbl_extend("force", opts_n, { desc = "Amp send buffer" }))
      map("v", "<leader>av", ":AmpPromptSelection<CR>", vim.tbl_extend("force", opts_n, { desc = "Amp send selection" }))
      map("v", "<leader>ar", ":AmpPromptRef<CR>", vim.tbl_extend("force", opts_n, { desc = "Amp send file ref" }))
      map("n", "<leader>ai", "<cmd>checkhealth amp<CR>", vim.tbl_extend("force", opts_n, { desc = "Amp status" }))
    end,
  },

  -- OpenCode AI
  {
    "NickvanDyke/opencode.nvim",
    dependencies = {
      { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
    },
    config = function()
      vim.g.opencode_opts = {}
      vim.o.autoread = true

      -- OpenCode keymaps (using Ctrl-based for quick access)
      vim.keymap.set({ "n", "x" }, "<C-a>", function()
        require("opencode").ask("@this: ", { submit = true })
      end, { desc = "Ask opencode" })

      vim.keymap.set({ "n", "x" }, "<C-x>", function()
        require("opencode").select()
      end, { desc = "Execute opencode action" })

      vim.keymap.set({ "n", "t" }, "<C-.>", function()
        require("opencode").toggle()
      end, { desc = "Toggle opencode" })

      vim.keymap.set({ "n", "x" }, "go", function()
        return require("opencode").operator("@this ")
      end, { desc = "Add range to opencode", expr = true })

      vim.keymap.set("n", "goo", function()
        return require("opencode").operator("@this ") .. "_"
      end, { desc = "Add line to opencode", expr = true })

      vim.keymap.set("n", "<S-C-u>", function()
        require("opencode").command("session.half.page.up")
      end, { desc = "Scroll opencode up" })

      vim.keymap.set("n", "<S-C-d>", function()
        require("opencode").command("session.half.page.down")
      end, { desc = "Scroll opencode down" })

      -- Alternative keymaps under <leader>a (AI group)
      vim.keymap.set("n", "<leader>aoa", function()
        require("opencode").ask("@this: ", { submit = true })
      end, { desc = "Ask opencode (AI)" })

      vim.keymap.set("n", "<leader>aoe", function()
        require("opencode").select()
      end, { desc = "Execute opencode action" })

      vim.keymap.set("n", "<leader>aot", function()
        require("opencode").toggle()
      end, { desc = "Toggle opencode" })

      -- Preserve increment/decrement with +/-
      vim.keymap.set("n", "+", "<C-a>", { noremap = true, desc = "Increment under cursor" })
      vim.keymap.set("n", "-", "<C-x>", { noremap = true, desc = "Decrement under cursor" })
    end,
  },
}

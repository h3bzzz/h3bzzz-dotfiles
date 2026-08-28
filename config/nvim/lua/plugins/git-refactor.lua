-- lua/plugins/git-refactor.lua
return {
  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "▎" },
          change = { text = "▎" },
          delete = { text = "▎" },
          topdelete = { text = "▎" },
          changedelete = { text = "▎" },
          untracked = { text = "▎" },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map("n", "]c", function()
            if vim.wo.diff then
              return "]c"
            end
            vim.schedule(function()
              gs.next_hunk()
            end)
            return "<Ignore>"
          end, { expr = true, desc = "Next hunk" })

          map("n", "[c", function()
            if vim.wo.diff then
              return "[c"
            end
            vim.schedule(function()
              gs.prev_hunk()
            end)
            return "<Ignore>"
          end, { expr = true, desc = "Prev hunk" })

          -- Actions
          map("n", "<leader>gs", gs.stage_hunk, { desc = "Git stage hunk" })
          map("n", "<leader>gr", gs.reset_hunk, { desc = "Git reset hunk" })
          map("v", "<leader>gs", function()
            gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, { desc = "Git stage hunk" })
          map("v", "<leader>gr", function()
            gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, { desc = "Git reset hunk" })
          map("n", "<leader>gS", gs.stage_buffer, { desc = "Git stage buffer" })
          map("n", "<leader>gu", gs.undo_stage_hunk, { desc = "Git undo stage hunk" })
          map("n", "<leader>gR", gs.reset_buffer, { desc = "Git reset buffer" })
          map("n", "<leader>gp", gs.preview_hunk, { desc = "Git preview hunk" })
          map("n", "<leader>gb", function()
            gs.blame_line({ full = true })
          end, { desc = "Git blame line" })
          map("n", "<leader>gd", gs.diffthis, { desc = "Git diff" })
          map("n", "<leader>gD", function()
            gs.diffthis("~")
          end, { desc = "Git diff (cached)" })
          map("n", "<leader>td", gs.toggle_deleted, { desc = "Toggle deleted" })
        end,
      })
    end,
  },

  -- Lazygit integration
  {
    "kdheepak/lazygit.nvim",
    cmd = "LazyGit",
    keys = {
      { "<leader>gg", "<cmd>LazyGit<CR>", desc = "LazyGit" },
      { "<leader>gl", "<cmd>LazyGitCurrentFile<CR>", desc = "LazyGit (current file)" },
      { "<leader>gf", "<cmd>LazyGitFilter<CR>", desc = "LazyGit filter" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },

  -- Refactoring toolkit
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter"
    },
    config = function()
      require("refactoring").setup({
        prompt_func_return_type = {
          go = true,
          cpp = true,
          c = true,
          java = true,
        },
        prompt_func_param_type = {
          go = true,
          cpp = true,
          c = true,
          java = true,
        },
      })
      
      vim.keymap.set("v", "<leader>rr", function()
        require("refactoring").select_refactor()
      end, { desc = "Refactor" })
      
      -- Extract function
      vim.keymap.set("v", "<leader>rf", function()
        require("refactoring").refactor("Extract Function")
      end, { desc = "Extract function" })
      
      -- Extract variable
      vim.keymap.set("v", "<leader>rv", function()
        require("refactoring").refactor("Extract Variable")
      end, { desc = "Extract variable" })
      
      -- Inline variable
      vim.keymap.set({ "n", "v" }, "<leader>ri", function()
        require("refactoring").refactor("Inline Variable")
      end, { desc = "Inline variable" })
    end,
  },
}



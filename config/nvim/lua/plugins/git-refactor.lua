-- lua/plugins/git-refactor.lua
return {
  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Lazygit integration
  {
    "kdheepak/lazygit.nvim",
    cmd = "LazyGit",
    keys = {
      { "<leader>gg", "<cmd>LazyGit<CR>", desc = "LazyGit" },
    },
  },

  -- Refactoring toolkit
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter", "lewis6991/async.nvim" },
    config = function()
      require("refactoring").setup({})
      vim.keymap.set("v", "<leader>rr", function()
        require("refactoring").select_refactor()
      end, { desc = "Refactor" })
    end,
  },
}


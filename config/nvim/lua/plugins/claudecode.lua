-- Claude Code (coder/claudecode.nvim)
-- Namespaced under <leader>ac to avoid overlap with the other AI tools
-- already living under <leader>a (Amp, OpenCode). Pattern matches the
-- existing subgroup convention: <leader>ao = OpenCode, <leader>ac = Claude.
return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeSelectModel",
      "ClaudeCodeAdd",
      "ClaudeCodeSend",
      "ClaudeCodeTreeAdd",
      "ClaudeCodeStatus",
      "ClaudeCodeStart",
      "ClaudeCodeStop",
      "ClaudeCodeOpen",
      "ClaudeCodeClose",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeCloseAllDiffs",
    },
    opts = {
      auto_start = true,
      log_level = "info",
      -- terminal_cmd = "~/.claude/local/claude", -- uncomment if using a local install
      focus_after_send = false,
      track_selection = true,
      terminal = {
        split_side = "right",
        split_width_percentage = 0.35,
        provider = "auto", -- prefers snacks (already installed), falls back to native
        auto_close = true,
        auto_insert = true,
      },
      diff_opts = {
        layout = "vertical",
        auto_resize_terminal = true,
      },
    },
    keys = {
      -- Group label
      { "<leader>ac", nil, desc = "Claude Code", icon = "✨" },

      -- Session
      { "<leader>acc", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>acf", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>acr", "<cmd>ClaudeCode --resume<cr>", desc = "Resume session" },
      { "<leader>acC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue last session" },
      { "<leader>acm", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select model" },
      { "<leader>acS", "<cmd>ClaudeCodeStatus<cr>", desc = "Connection status" },

      -- Context
      { "<leader>acb", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>acs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection" },
      {
        "<leader>act",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file from explorer",
        ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw", "snacks_picker_list" },
      },

      -- Diff review
      { "<leader>aca", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>acd", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
      { "<leader>acx", "<cmd>ClaudeCodeCloseAllDiffs<cr>", desc = "Close all diffs" },
    },
  },
}

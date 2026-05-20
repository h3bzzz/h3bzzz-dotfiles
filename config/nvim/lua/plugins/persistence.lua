-- ~/.config/nvim/lua/plugins/persistence.lua
return {
  "folke/persistence.nvim",
  event = "BufReadPre", -- load before reading a buffer
  opts = {
    options = { "buffers", "curdir", "tabpages", "winsize" },
  },
  keys = {
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Stop Session" },
  },
}


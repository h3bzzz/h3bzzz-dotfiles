-- plugins/flash.lua
return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Flash Remote" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Flash TS Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Flash Toggle" },
    },
  },
}


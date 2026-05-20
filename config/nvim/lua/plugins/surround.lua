-- ~/.config/nvim/lua/plugins/nvim-surround.lua
return {
  "kylechui/nvim-surround",
  event = "VeryLazy", -- load when it's unlikely to block startup
  config = function()
    require("nvim-surround").setup({})
  end,
}


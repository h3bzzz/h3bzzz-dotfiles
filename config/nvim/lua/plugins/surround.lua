-- ~/.config/nvim/lua/plugins/nvim-surround.lua
return {
  "kylechui/nvim-surround",
  version = "*", -- Use stable version
  event = "VeryLazy",
  config = function()
    require("nvim-surround").setup({
      -- Use default keymaps - v4 handles keymaps differently
      -- The plugin will automatically set up keymaps
      -- To customize, use buffer_setup in ftplugin files
    })
  end,
}

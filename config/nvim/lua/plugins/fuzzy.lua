-- ~/.config/nvim/lua/plugins/telescope-fzf-native.lua
return {
  "nvim-telescope/telescope-fzf-native.nvim",
  build = "make", -- compile native fzf sorter
  cond = vim.fn.executable("make") == 1, -- only if make is available
  config = function()
    require("telescope").load_extension("fzf")
  end,
}


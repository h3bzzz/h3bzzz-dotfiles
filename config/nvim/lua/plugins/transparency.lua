return {
  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    config = function()
      require("transparent").setup({
        enable = true,
        extra_groups = {
          "NormalFloat",
          "TelescopeNormal",
          "TelescopeBorder",
          "TelescopePromptBorder",
          "TelescopePromptNormal",
          "TelescopeResultsNormal",
          "TelescopeResultsBorder",
          "TelescopePreviewNormal",
          "TelescopePreviewBorder",
          "WhichKeyNormal",
          "WhichKeyBorder",
          "NvimTreeNormal",
          "BufferLineTabClose",
          "BufferLineBufferSelected",
          "BufferLineBufferVisible",
          "LazyNormal",
          "LazyBorder",
          "MasonNormal",
          "MasonBorder",
          "NoiceNormal",
          "NoiceBorder",
        },
      })
    end,
  },
}

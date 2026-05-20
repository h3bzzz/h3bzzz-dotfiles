-- ~/.config/nvim/lua/plugins/go.lua
return {
  {
    "ray-x/go.nvim",
    dependencies = { -- these are required for full functionality
      "ray-x/guihua.lua", -- UI helper
      "neovim/nvim-lspconfig", -- LSP integration
    },
    ft = { "go", "gomod" }, -- lazy load on Go files
    build = ':lua require("go.install").update_all_sync()', -- install/update binaries
    config = function()
      require("go").setup({
        -- examples, tweak as you like:
        gofmt = "gofumpt", -- format tool
        max_line_len = 120,
        lsp_cfg = true, -- use default LSP config
        dap_debug = true, -- enable DAP debugging
      })
    end,
  },
}


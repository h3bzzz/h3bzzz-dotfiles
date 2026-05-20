-- lua/plugins/terminal.lua
return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 14,
        shade_terminal = true,
        direction = "float",
      })

      vim.keymap.set("n", "<leader>tt", "<cmd>ToggleTerm<CR>", { desc = "Toggle terminal" })
    end,
  },
}


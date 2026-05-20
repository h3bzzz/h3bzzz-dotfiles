return {
  -- Multi-cursor support (like VS Code)
  {
    "mg979/vim-visual-multi",
    lazy = false,
    init = function()
      vim.g.VM_maps = {
        ["Find Under"] = "<C-n>",
        ["Find Subword Under"] = "<C-n>",
        ["Select All"] = "<C-S-n>",
        ["Start Regex Search"] = "\\\\/",
        ["Add Cursor Down"] = "<C-Down>",
        ["Add Cursor Up"] = "<C-Up>",
        ["Add Cursor At Pos"] = "<C-x>",
        ["Remove Region"] = "q",
        ["Skip Region"] = "<C-s>",
        ["Undo"] = "u",
        ["Redo"] = "<C-r>",
      }
      vim.g.VM_mouse_mappings = 0
      vim.g.VM_theme = "iceblue"
    end,
  },

  -- UndoTree for visual undo history
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>uu", "<cmd>UndotreeToggle<cr>", desc = "Toggle UndoTree" },
    },
    config = function()
      vim.g.undotree_WindowLayout = 2
      vim.g.undotree_SetFocusWhenToggle = 1
    end,
  },

  -- Override Telescope config for better defaults
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = {
          prompt_position = "top",
        },
        sorting_strategy = "ascending",
      },
    },
  },

  -- THEMERY + curated mega colorscheme list
  {
    "zaldih/themery.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("themery").setup({
        themes = {
          -- 🌙 Popular Mainstream
          "rose-pine",
          "catppuccin",
          "tokyonight",
          "kanagawa",
          "nightfox",
          "onedark",
          "gruvbox-material",
          "github_dark",
          "everforest",
          "vscode",
          "dracula",
          -- 🎨 Stylish Nerd Favorites
          "oxocarbon",
          "nord",
          "nordic",
          "moonfly",
          "oh-lucy",
          "tokyodark",
          "aquarium",
          "darkplus",
          -- 💻 Retro Hacker Vibes
          "landscape",
          "tender",
          "rigel",
          
          -- 🔥 Experimental & Unique
          "citruszest",
          "mellow",
          "nvimgelion",
          "spaceduck",
          "kimbox",
          -- 🖤 Minimal & Clean
          "carbonfox",
          "terafox",
          "dawnfox",
          "dayfox",
          "nightfly",
          "melange",
          "ayu-dark",
          "ayu-mirage",
          "ayu-light",
        },
        livePreview = true,
        persistent = true,
        defaultTheme = "rose-pine",
      })

      vim.keymap.set("n", "<leader>th", "<cmd>Themery<cr>", { desc = "Theme Picker" })
    end,
  },

  -- 🌙 Colorscheme plugin sources
  { "rose-pine/neovim", name = "rose-pine", lazy = false, priority = 1000 },
  { "catppuccin/nvim", name = "catppuccin", lazy = false },
  { "folke/tokyonight.nvim", lazy = false },
  { "rebelot/kanagawa.nvim", lazy = false },
  { "EdenEast/nightfox.nvim", lazy = false },
  { "navarasu/onedark.nvim", name = "onedark", lazy = false },
  { "sainnhe/gruvbox-material", lazy = false },
  { "projekt0n/github-nvim-theme", lazy = false },
  { "sainnhe/everforest", lazy = false },
  { "Mofiqul/vscode.nvim", name = "vscode", lazy = false },
  { "Mofiqul/dracula.nvim", name = "dracula", lazy = false },
  { "nyoom-engineering/oxocarbon.nvim", lazy = false },
  { "shaunsingh/nord.nvim", name = "nord", lazy = false },
  { "AlexvZyl/nordic.nvim", name = "nordic", lazy = false },
  { "bluz71/vim-moonfly-colors", name = "moonfly", lazy = false },
  { "Yazeed1s/oh-lucy.nvim", name = "oh-lucy", lazy = false },
  { "tiagovla/tokyodark.nvim", name = "tokyodark", lazy = false },
  { "frenzyexists/aquarium-vim", name = "aquarium", lazy = false },
  { "lunarvim/darkplus.nvim", name = "darkplus", lazy = false },
  { "itchyny/landscape.vim", name = "landscape", lazy = false },
  { "jacoborus/tender.vim", name = "tender", lazy = false },
  { "rigellute/rigel", name = "rigel", lazy = false },
  { "zootedb0t/citruszest.nvim", name = "citruszest", lazy = false },
  { "kvrohit/mellow.nvim", name = "mellow", lazy = false },
  { "nyngwang/nvimgelion", name = "nvimgelion", lazy = false },
  { "pineapplegiant/spaceduck", name = "spaceduck", lazy = false },
  { "lmburns/kimbox", name = "kimbox", lazy = false },
  { "EdenEast/nightfox.nvim", name = "carbonfox", lazy = false }, -- Nightfox variants
  { "EdenEast/nightfox.nvim", name = "terafox", lazy = false },
  { "EdenEast/nightfox.nvim", name = "dawnfox", lazy = false },
  { "EdenEast/nightfox.nvim", name = "dayfox", lazy = false },
  { "bluz71/vim-nightfly-colors", name = "nightfly", lazy = false },
  { "savq/melange-nvim", name = "melange", lazy = false },
  { "Shatur/neovim-ayu", name = "ayu", lazy = false },
}


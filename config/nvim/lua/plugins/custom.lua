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
        ["Add Cursor At Pos"] = "<C-S-x>",
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
          "rose-pine-moon",
          "rose-pine-dawn",
          "catppuccin-mocha",
          "catppuccin-macchiato",
          "catppuccin-frappe",
          "catppuccin-latte",
          "tokyonight-night",
          "tokyonight-storm",
          "tokyonight-day",
          "tokyonight-moon",
          "kanagawa",
          "kanagawa-wave",
          "kanagawa-dragon",
          "kanagawa-lotus",
          "nightfox",
          "nordfox",
          "terafox",
          "carbonfox",
          "dawnfox",
          "dayfox",
          "duskfox",
          "onedark",
          "gruvbox-material",
          "github_dark",
          "github_dark_default",
          "github_dimmed",
          "github_light",
          "everforest",
          "vscode",
          "dracula",
          "dracula-soft",
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
          "nightfly",
          "melange",
          "ayu-dark",
          "ayu-mirage",
          "ayu-light",
          -- 🤖 2025-2026 newcomers & trending
          "cyberdream",
          "vague",
          "evergarden",
          "bamboo",
          "miasma",
          "solarized-osaka",
          "solarized-osaka-light",
          "solarized-osaka-vivid",
          "material",
          "edge",
          "sonokai",
        },
        livePreview = true,
        persistent = true,
        defaultTheme = "rose-pine",
      })

      vim.keymap.set("n", "<leader>tp", "<cmd>Themery<cr>", { desc = "Theme picker" })
    end,
  },

  -- 🌹 Rosé Pine
  --
  -- One spec, not three. Previously `rose-pine`, `rose-pine-moon` and
  -- `rose-pine-dawn` were three separate specs, each lazy=false priority=1000
  -- and each calling require("rose-pine").setup(). setup() is global, so the
  -- last one won: the plugin ended up configured with variant="dawn" and the
  -- dawn spec also ran `colorscheme rose-pine-dawn`, which is why a bare
  -- `rose-pine` rendered as the light Dawn variant at startup.
  --
  -- The colors/rose-pine-{main,moon,dawn}.lua files that ship with the plugin
  -- each call colorscheme("<variant>") explicitly, so all three Themery entries
  -- still work from a single setup() with no variant pinned.
  --
  -- `main` takes its palette from the wallpaper when matugen has generated one.
  -- The override is keyed by variant, so moon and dawn stay true Rosé Pine.
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 1000,
    config = function()
      local ok, wallpaper = pcall(require, "config.matugen-palette")
      require("rose-pine").setup({
        dark_variant = "main",
        styles = {
          bold = true,
          italic = true,
          transparency = true,
        },
        palette = ok and { main = wallpaper } or {},
      })
    end,
  },

  -- 🐱 Catppuccin variants with transparency
  {
    "catppuccin/nvim",
    name = "catppuccin-mocha",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = true,
        term_colors = true,
        integrations = {
          telescope = true,
          nvimtree = true,
          cmp = true,
          gitsigns = true,
          treesitter = true,
          notify = true,
          mini = true,
          which_key = true,
        },
      })
    end,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin-macchiato",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "macchiato",
        transparent_background = true,
        term_colors = true,
        integrations = {
          telescope = true,
          nvimtree = true,
          cmp = true,
          gitsigns = true,
          treesitter = true,
          notify = true,
          mini = true,
          which_key = true,
        },
      })
    end,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin-frappe",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "frappe",
        transparent_background = true,
        term_colors = true,
        integrations = {
          telescope = true,
          nvimtree = true,
          cmp = true,
          gitsigns = true,
          treesitter = true,
          notify = true,
          mini = true,
          which_key = true,
        },
      })
    end,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin-latte",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "latte",
        transparent_background = true,
        term_colors = true,
        integrations = {
          telescope = true,
          nvimtree = true,
          cmp = true,
          gitsigns = true,
          treesitter = true,
          notify = true,
          mini = true,
          which_key = true,
        },
      })
    end,
  },

  -- 🗼 Tokyo Night variants with transparency
  {
    "folke/tokyonight.nvim",
    name = "tokyonight-night",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = true,
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          sidebars = "transparent",
          floats = "transparent",
        },
      })
    end,
  },
  {
    "folke/tokyonight.nvim",
    name = "tokyonight-storm",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "storm",
        transparent = true,
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          sidebars = "transparent",
          floats = "transparent",
        },
      })
    end,
  },
  {
    "folke/tokyonight.nvim",
    name = "tokyonight-day",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "day",
        transparent = true,
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          sidebars = "transparent",
          floats = "transparent",
        },
      })
    end,
  },
  {
    "folke/tokyonight.nvim",
    name = "tokyonight-moon",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "moon",
        transparent = true,
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          sidebars = "transparent",
          floats = "transparent",
        },
      })
    end,
  },

  -- ⛩️ Kanagawa variants with transparency
  {
    "rebelot/kanagawa.nvim",
    name = "kanagawa",
    lazy = false,
    config = function()
      require("kanagawa").setup({
        transparent = true,
        terminalColors = true,
        theme = "default",
      })
    end,
  },
  {
    "rebelot/kanagawa.nvim",
    name = "kanagawa-wave",
    lazy = false,
    config = function()
      require("kanagawa").setup({
        transparent = true,
        terminalColors = true,
        theme = "wave",
      })
    end,
  },
  {
    "rebelot/kanagawa.nvim",
    name = "kanagawa-dragon",
    lazy = false,
    config = function()
      require("kanagawa").setup({
        transparent = true,
        terminalColors = true,
        theme = "dragon",
      })
    end,
  },
  {
    "rebelot/kanagawa.nvim",
    name = "kanagawa-lotus",
    lazy = false,
    config = function()
      require("kanagawa").setup({
        transparent = true,
        terminalColors = true,
        theme = "lotus",
      })
    end,
  },

  -- 🦊 Nightfox variants with transparency
  {
    "EdenEast/nightfox.nvim",
    name = "nightfox",
    lazy = false,
    config = function()
      require("nightfox").setup({
        options = {
          transparent = true,
          terminal_colors = true,
        },
      })
    end,
  },
  {
    "EdenEast/nightfox.nvim",
    name = "nordfox",
    lazy = false,
    config = function()
      require("nightfox").setup({
        options = {
          transparent = true,
          terminal_colors = true,
        },
      })
    end,
  },
  {
    "EdenEast/nightfox.nvim",
    name = "terafox",
    lazy = false,
    config = function()
      require("nightfox").setup({
        options = {
          transparent = true,
          terminal_colors = true,
        },
      })
    end,
  },
  {
    "EdenEast/nightfox.nvim",
    name = "carbonfox",
    lazy = false,
    config = function()
      require("nightfox").setup({
        options = {
          transparent = true,
          terminal_colors = true,
        },
      })
    end,
  },
  {
    "EdenEast/nightfox.nvim",
    name = "dawnfox",
    lazy = false,
    config = function()
      require("nightfox").setup({
        options = {
          transparent = true,
          terminal_colors = true,
        },
      })
    end,
  },
  {
    "EdenEast/nightfox.nvim",
    name = "dayfox",
    lazy = false,
    config = function()
      require("nightfox").setup({
        options = {
          transparent = true,
          terminal_colors = true,
        },
      })
    end,
  },
  {
    "EdenEast/nightfox.nvim",
    name = "duskfox",
    lazy = false,
    config = function()
      require("nightfox").setup({
        options = {
          transparent = true,
          terminal_colors = true,
        },
      })
    end,
  },

  -- 🎨 Other colorschemes with transparency
  {
    "navarasu/onedark.nvim",
    name = "onedark",
    lazy = false,
    config = function()
      require("onedark").setup({
        style = "dark",
        transparent = true,
        term_colors = true,
      })
    end,
  },
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    config = function()
      vim.g.gruvbox_material_enable_italic = 1
      vim.g.gruvbox_material_transparent_background = 1
      vim.g.gruvbox_material_background = "medium"
    end,
  },
  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    name = "github_dark",
    config = function()
      require("github-theme").setup({
        options = {
          transparent = true,
        },
      })
    end,
  },
  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    name = "github_dark_default",
    config = function()
      require("github-theme").setup({
        options = {
          transparent = true,
        },
      })
    end,
  },
  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    name = "github_dimmed",
    config = function()
      require("github-theme").setup({
        options = {
          transparent = true,
        },
      })
    end,
  },
  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    name = "github_light",
    config = function()
      require("github-theme").setup({
        options = {
          transparent = true,
        },
      })
    end,
  },
  {
    "sainnhe/everforest",
    lazy = false,
    config = function()
      vim.g.everforest_enable_italic = 1
      vim.g.everforest_transparent_background = 1
      vim.g.everforest_background = "medium"
    end,
  },
  {
    "Mofiqul/vscode.nvim",
    name = "vscode",
    lazy = false,
    config = function()
      require("vscode").setup({
        transparent = true,
      })
    end,
  },
  {
    "Mofiqul/dracula.nvim",
    name = "dracula",
    lazy = false,
    config = function()
      require("dracula").setup({
        transparent_bg = true,
      })
    end,
  },
  {
    "Mofiqul/dracula.nvim",
    name = "dracula-soft",
    lazy = false,
    config = function()
      require("dracula").setup({
        transparent_bg = true,
        soft = true,
      })
    end,
  },
  {
    "nyoom-engineering/oxocarbon.nvim",
    lazy = false,
    build = false, -- skip dev-only fennel build (rocks are disabled globally too)
    config = function()
      vim.opt.background = "dark"
    end,
  },
  {
    "shaunsingh/nord.nvim",
    name = "nord",
    lazy = false,
    config = function()
      vim.g.nord_contrast = false
      vim.g.nord_disable_background = true
      vim.g.nord_italic = true
      vim.g.nord_bold = true
    end,
  },
  {
    "AlexvZyl/nordic.nvim",
    name = "nordic",
    lazy = false,
    config = function()
      require("nordic").setup({
        transparent = true,
      })
    end,
  },
  { "bluz71/vim-moonfly-colors", name = "moonfly", lazy = false },
  { "Yazeed1s/oh-lucy.nvim", name = "oh-lucy", lazy = false },
  {
    "tiagovla/tokyodark.nvim",
    name = "tokyodark",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyodark").setup({
        transparent_background = true,
        gamma = 1.0,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
        },
        custom_highlights = {
          VertSplit = { fg = "#121220" },
        },
      })
    end,
  },
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
  { "bluz71/vim-nightfly-colors", name = "nightfly", lazy = false },
  {
    "savq/melange-nvim",
    name = "melange",
    lazy = false,
    config = function()
      vim.opt.background = "dark"
    end,
  },
  {
    "Shatur/neovim-ayu",
    name = "ayu",
    lazy = false,
    config = function()
      require("ayu").setup({
        mirage = false,
        overrides = {},
      })
    end,
  },

  -- 🤖 Cyberdream — high-contrast futuristic theme
  {
    "scottmckendry/cyberdream.nvim",
    name = "cyberdream",
    lazy = false,
    priority = 1000,
    config = function()
      require("cyberdream").setup({
        transparent = true,
        terminal_colors = true,
        italic_comments = true,
        extensions = {
          telescope = true,
          notify = true,
          mini = true,
          whichkey = true,
        },
      })
    end,
  },

  -- 🌫️ Vague — cool, dark, low-contrast pastel theme
  {
    "vague-theme/vague.nvim",
    name = "vague",
    lazy = false,
    priority = 1000,
    config = function()
      require("vague").setup({
        transparent = true,
        bold = true,
        italic = true,
      })
    end,
  },

  -- 🌹 Evergarden — comfy colorscheme for cozy morning coding
  {
    "everviolet/nvim",
    name = "evergarden",
    lazy = false,
    priority = 1000,
    config = function()
      require("evergarden").setup({
        theme = {
          variant = "fall",
          accent = "green",
        },
        editor = {
          transparent_background = true,
        },
      })
    end,
  },

  -- 🎋 Bamboo — warm green theme
  {
    "ribru17/bamboo.nvim",
    name = "bamboo",
    lazy = false,
    priority = 1000,
    config = function()
      require("bamboo").setup({
        style = "vulgaris",
        transparent = true,
        term_colors = true,
      })
      require("bamboo").load()
    end,
  },

  -- 🌲 Miasma — foggy woods-inspired dark theme
  {
    "xero/miasma.nvim",
    name = "miasma",
    lazy = false,
    priority = 1000,
  },

  -- 🏯 Solarized Osaka — modernized Solarized
  {
    "craftzdog/solarized-osaka.nvim",
    name = "solarized-osaka",
    lazy = false,
    priority = 1000,
    config = function()
      require("solarized-osaka").setup({
        transparent = true,
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          sidebars = "transparent",
          floats = "transparent",
        },
      })
    end,
  },
  {
    "craftzdog/solarized-osaka.nvim",
    name = "solarized-osaka-light",
    lazy = false,
    priority = 1000,
    config = function()
      require("solarized-osaka").setup({
        transparent = true,
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          sidebars = "transparent",
          floats = "transparent",
        },
      })
    end,
  },
  {
    "craftzdog/solarized-osaka.nvim",
    name = "solarized-osaka-vivid",
    lazy = false,
    priority = 1000,
    config = function()
      require("solarized-osaka").setup({
        style = "vivid",
        transparent = true,
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          sidebars = "transparent",
          floats = "transparent",
        },
      })
    end,
  },

  -- 🔱 Material — Material palette for Neovim
  {
    "marko-cerovac/material.nvim",
    name = "material",
    lazy = false,
    priority = 1000,
    config = function()
      require("material").setup({
        disable = {
          background = true,
        },
        plugins = {
          "blink",
          "gitsigns",
          "mini",
          "neo-tree",
          "neotest",
          "noice",
          "nvim-notify",
          "telescope",
          "which-key",
        },
      })
      vim.g.material_style = "oceanic"
    end,
  },

  -- 🌊 Edge — clean & elegant Atom One / Material inspired
  {
    "sainnhe/edge",
    name = "edge",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.edge_style = "default"
      vim.g.edge_enable_italic = 1
      vim.g.edge_transparent_background = 1
    end,
  },

  -- 🍣 Sonokai — high-contrast vivid Monokai Pro inspired
  {
    "sainnhe/sonokai",
    name = "sonokai",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.sonokai_style = "default"
      vim.g.sonokai_enable_italic = 1
      vim.g.sonokai_transparent_background = 1
    end,
  },
}

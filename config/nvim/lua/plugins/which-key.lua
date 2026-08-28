return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    -- Add groups for better organization
    spec = {
      -- AI group
      { "<leader>a", group = "AI", icon = "🤖" },
      -- Amp keymaps
      { "<leader>as", desc = "Send message (Amp)" },
      { "<leader>ab", desc = "Send buffer (Amp)" },
      { "<leader>ar", desc = "Send file ref (Amp)" },
      { "<leader>ai", desc = "Amp status" },
      -- Claude Code subgroup
      { "<leader>ac", group = "Claude Code", icon = "✨" },
      { "<leader>acc", desc = "Toggle Claude" },
      { "<leader>acf", desc = "Focus Claude" },
      { "<leader>acr", desc = "Resume session" },
      { "<leader>acC", desc = "Continue last session" },
      { "<leader>acm", desc = "Select model" },
      { "<leader>acS", desc = "Connection status" },
      { "<leader>acb", desc = "Add current buffer" },
      { "<leader>acs", desc = "Send selection" },
      { "<leader>act", desc = "Add file from explorer" },
      { "<leader>aca", desc = "Accept diff" },
      { "<leader>acd", desc = "Deny diff" },
      { "<leader>acx", desc = "Close all diffs" },

      -- Buffer group
      { "<leader>b", group = "Buffer" },
      { "<leader>bb", desc = "Switch buffer" },
      { "<leader>bd", desc = "Delete buffer" },
      { "<leader>bo", desc = "Delete other buffers" },
      { "<leader>bn", desc = "New buffer" },
      
      -- Code/LSP group
      { "<leader>c", group = "Code", icon = "💻" },
      { "<leader>cR", desc = "Switch Source/Header (C/C++)" },
      { "<leader>cr", desc = "Rename" },
      { "<leader>ca", desc = "Code action" },
      { "<leader>cf", desc = "Format" },
      
      -- Debug group
      { "<leader>d", group = "Debug", icon = "🐛" },
      { "<leader>db", desc = "Toggle breakpoint" },
      { "<leader>dc", desc = "Continue" },
      { "<leader>di", desc = "Step into" },
      { "<leader>do", desc = "Step over" },
      { "<leader>dO", desc = "Step out" },
      { "<leader>dr", desc = "Toggle REPL" },
      { "<leader>du", desc = "Toggle UI" },
      { "<leader>dt", desc = "Debug test (Go)" },
      { "<leader>dl", desc = "Debug last test" },
      
      -- File/Find group (Snacks Picker)
      { "<leader>f", group = "Find", icon = "🔍" },
      { "<leader>ff", desc = "Find files" },
      { "<leader>fg", desc = "Live grep" },
      { "<leader>fb", desc = "Find buffers" },
      { "<leader>fh", desc = "Help tags" },
      { "<leader>fr", desc = "Recent files" },
      { "<leader>fc", desc = "Find config files" },
      { "<leader>fk", desc = "Find keymaps" },
      { "<leader>fs", desc = "Find symbols" },
      
      -- Git group
      { "<leader>g", group = "Git", icon = "🌿" },
      { "<leader>gg", desc = "LazyGit" },
      { "<leader>gf", desc = "Lazygit file history" },
      { "<leader>gl", desc = "Lazygit log" },
      { "<leader>gs", desc = "Git status" },
      { "<leader>gb", desc = "Git blame line" },
      { "<leader>gd", desc = "Git diff" },
      { "<leader>gD", desc = "Git diff (cached)" },
      { "<leader>gp", desc = "Preview hunk" },
      
      -- Harpoon group
      { "<leader>h", group = "Harpoon", icon = "🔱" },
      { "<leader>ha", desc = "Add file" },
      { "<leader>hh", desc = "Toggle menu" },
      { "<leader>h1", desc = "File 1" },
      { "<leader>h2", desc = "File 2" },
      { "<leader>h3", desc = "File 3" },
      { "<leader>h4", desc = "File 4" },
      
      -- Go group
      { "<leader>G", group = "Go", icon = "🐹" },
      { "<leader>Gt", desc = "Go test" },
      { "<leader>GT", desc = "Go test function" },
      { "<leader>Gr", desc = "Go run" },
      { "<leader>Gb", desc = "Go build" },
      { "<leader>Gi", desc = "Go imports" },
      { "<leader>Gf", desc = "Go format" },
      { "<leader>Gc", desc = "Go coverage" },
      { "<leader>Gd", desc = "Go doc" },
      { "<leader>Ge", desc = "Go add if err" },
      { "<leader>Gs", desc = "Go fill struct" },
      { "<leader>Gw", desc = "Go fill switch" },
      
      -- Session/Persistence group
      { "<leader>q", group = "Session", icon = "💾" },
      { "<leader>qs", desc = "Restore session" },
      { "<leader>ql", desc = "Restore last session" },
      { "<leader>qd", desc = "Stop session" },
      
      -- Refactor group
      { "<leader>r", group = "Refactor", icon = "🔧" },
      { "<leader>rr", desc = "Select refactor" },
      { "<leader>rf", desc = "Extract function" },
      { "<leader>rv", desc = "Extract variable" },
      { "<leader>ri", desc = "Inline variable" },
      
      -- Search & Replace group
      { "<leader>s", group = "Search/Replace", icon = "🔎" },
      { "<leader>sr", desc = "Search and Replace" },
      { "<leader>sR", desc = "Search and Replace (current file)" },
      
      -- Terminal / Theme group (shared <leader>t prefix)
      { "<leader>t", group = "Terminal/Theme", icon = "🖥️" },
      { "<leader>tt", desc = "Toggle terminal" },
      { "<leader>tf", desc = "Floating terminal" },
      { "<leader>th", desc = "Horizontal terminal" },
      { "<leader>tv", desc = "Vertical terminal" },
      { "<leader>tp", desc = "Theme picker" },
      
      -- Theme/UI group
      { "<leader>u", group = "UI", icon = "🎨" },
      { "<leader>uu", desc = "Undo tree" },
      { "<leader>un", desc = "Dismiss notifications" },

      -- Test group (neotest)
      { "<leader>T", group = "Test", icon = "🧪" },
      { "<leader>Tt", desc = "Run nearest" },
      { "<leader>TT", desc = "Run file" },
      { "<leader>Ts", desc = "Toggle summary" },
      { "<leader>To", desc = "Show output" },
      { "<leader>TO", desc = "Toggle output panel" },
      { "<leader>Tw", desc = "Toggle watch" },
      { "<leader>Td", desc = "Debug nearest" },

      -- Zen/Focus group
      { "<leader>z", group = "Zen/Focus", icon = "🧘" },
      { "<leader>z", desc = "Toggle Zen Mode" },
      { "<leader>Z", desc = "Toggle Zoom" },
      
      -- Notifications
      { "<leader>n", group = "Notifications", icon = "🔔" },
    },
    
    -- Window options
    win = {
      border = "rounded",
      padding = { 2, 2, 2, 2 },
    },
    
    -- Layout options
    layout = {
      height = { min = 4, max = 25 },
      width = { min = 20, max = 50 },
      spacing = 3,
      align = "left",
    },
    
    -- Icons
    icons = {
      breadcrumb = "»",
      separator = "➜",
      group = "+",
    },
    
    -- Disable on certain file types
    disable = {
      ft = { "TelescopePrompt", "lazy", "mason", "snacks_picker_input" },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Keymaps",
    },
    {
      "<c-w><space>",
      function()
        require("which-key").show({ keys = "<c-w>", loop = true })
      end,
      desc = "Window Hydra Mode",
    },
  },
}

-- Path to lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop

-- Install lazy.nvim if missing
if not uv.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    lazyrepo,
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

-- Prepend lazy.nvim to runtime path
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- LazyVim core
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- Load all plugins from lua/plugins folder
    { import = "plugins" },
  },
  defaults = {
    lazy = false, -- Load everything on startup
    version = false, -- Always use latest commit
  },
  install = {
    colorscheme = { "tokyonight", "habamax" },
  },
  -- Disable lazy's luarocks integration. The system has no lua5.1 binary and
  -- lazy's toolchain is Lua 5.5, so rock builds (oxocarbon's fennel dep) fail.
  -- Nothing here needs a runtime rock: oxocarbon ships compiled lua, and
  -- image.nvim uses processor = "magick_cli" (the ImageMagick CLI, not the rock).
  rocks = {
    enabled = false,
  },
  checker = {
    enabled = true,
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})


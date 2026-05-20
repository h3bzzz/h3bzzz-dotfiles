-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

-- Better Search 
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.g.ai_cmp = false

-- Indentation
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftround = true
vim.opt.smartindent = true
vim.opt.clipboard = "unnamedplus"

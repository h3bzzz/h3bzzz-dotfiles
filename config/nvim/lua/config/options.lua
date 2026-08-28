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

-- Indentation
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftround = true
vim.opt.smartindent = true
vim.opt.clipboard = "unnamedplus"

-- Transparency settings - slightly darker (less transparent)
vim.opt.pumblend = 5    -- Popup menu transparency (5% transparent = 95% opaque)
vim.opt.winblend = 5    -- Floating window transparency (5% transparent = 95% opaque)

-- Auto command to make background transparent
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    -- Make Normal and other background-holding groups transparent
    vim.api.nvim_set_hl(0, "Normal", { bg = "none", ctermbg = "none" })
    vim.api.nvim_set_hl(0, "NormalNC", { bg = "none", ctermbg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none", ctermbg = "none" })
    vim.api.nvim_set_hl(0, "SignColumn", { bg = "none", ctermbg = "none" })
    vim.api.nvim_set_hl(0, "Folded", { bg = "none", ctermbg = "none" })
    vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none", ctermbg = "none" })
  end,
})

-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Move visual selection up/down
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Escape in insert and visual mode
vim.keymap.set({ "i", "v", "s" }, "<C-c>", "<Esc>", { silent = true, desc = "Escape" })

-- Theme picker is provided by themery.nvim (<leader>tp).

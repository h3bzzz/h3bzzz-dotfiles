-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Ensure transparency is applied after colorscheme loads
vim.api.nvim_create_autocmd("UIEnter", {
  once = true,
  callback = function()
    -- Trigger the transparency autocmd manually on startup
    vim.cmd("doautocmd ColorScheme")
  end,
})

-- Markdown and plain text: read like a document, not like source code.
-- Registered after LazyVim's lazyvim_wrap_spell autocmd on the same event, so
-- this one runs last and wins. Spell stays off until <leader>us, text wraps at
-- word boundaries, and format-on-save stays out of files you only opened to
-- read (<leader>cf still formats on demand). Keymaps live in plugins/markdown.lua.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("h3bzzz_prose", { clear = true }),
  pattern = { "markdown", "markdown.mdx", "text" },
  callback = function(ev)
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.breakindentopt = ""
    vim.opt_local.showbreak = "  " -- render-markdown repeats quote bars on wrapped lines with exactly this
    vim.opt_local.spell = false
    vim.opt_local.list = false -- no trailing-space dots; two trailing spaces are a markdown line break
    vim.opt_local.conceallevel = 2
    vim.b[ev.buf].autoformat = false
  end,
})

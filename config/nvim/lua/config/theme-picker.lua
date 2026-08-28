-- lua/config/theme_picker.lua
local M = {}

-- Fallback picker (vim.ui.select) if themery not available
local function fallback_picker()
  local colors = vim.fn.getcompletion("", "color")
  local current = vim.g.colors_name or "none"

  vim.ui.select(colors, {
    prompt = "Colorscheme (vim.ui.select) - current: " .. current,
  }, function(choice)
    if not choice then return end
    local ok, err = pcall(vim.cmd, "colorscheme " .. choice)
    if not ok then
      vim.notify("colorscheme failed: " .. tostring(err), vim.log.levels.ERROR)
    else
      vim.notify("colorscheme: " .. choice)
    end
  end)
end

function M.setup()
  -- If themery is installed use it; otherwise fallback to vim.ui.select picker
  local ok, themery = pcall(require, "themery")
  if ok and themery then
    -- Map <leader>tp to Themery
    vim.keymap.set("n", "<leader>tp", "<cmd>Themery<CR>", { noremap = true, silent = true, desc = "Theme picker (Themery)" })
  else
    -- Map <leader>tp to the fallback picker
    vim.keymap.set("n", "<leader>tp", fallback_picker, { noremap = true, silent = true, desc = "Theme picker (fallback)" })
  end
end

return M


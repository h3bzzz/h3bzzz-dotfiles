-- Rose Pine Hyprland Lua entrypoint.
-- Hyprland 0.55+ prefers this file over hyprland.conf at startup.

local home = os.getenv("HOME") or "."
local config_home = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local hypr_config_dir = config_home .. "/hypr"

package.path = hypr_config_dir .. "/lua/?.lua;" .. package.path

require("autostart")
require("settings")
require("binds")
require("rules")
require("extras")

-- Machine-specific overrides: lua/local.lua is gitignored and optional. It
-- loads last, so anything in it wins -- monitor layout for this box, a
-- different terminal, extra binds. Example:
--   hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1.25 })
local has_local, local_err = pcall(require, "local")
if not has_local and not tostring(local_err):find("module 'local' not found", 1, true) then
    hl.notification.create({ text = "lua/local.lua: " .. tostring(local_err), timeout = 8000 })
end

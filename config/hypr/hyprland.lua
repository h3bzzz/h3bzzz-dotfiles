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

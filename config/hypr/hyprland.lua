local home = os.getenv("HOME") or "/home/h3bzzz"
local config_home = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local hypr_config_dir = config_home .. "/hypr"

package.path = hypr_config_dir .. "/lua/?.lua;" .. package.path

require("autostart")
require("settings")
require("screensaver")
require("binds")
require("rules")

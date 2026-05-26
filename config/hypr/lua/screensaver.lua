local screensaver_active = false
local home = os.getenv("HOME") or "/home/h3bzzz"

local function start_screensaver()
    screensaver_active = true
    hl.exec_cmd(home .. "/.config/hypr/screensaver/start-screensaver.sh &")
end

local function stop_screensaver()
    if screensaver_active then
        screensaver_active = false
        hl.exec_cmd("pkill -f com\\.tte\\.screensaver")
    end
end

_G.start_screensaver = start_screensaver
_G.stop_screensaver = stop_screensaver

hl.on("window.open", function(window)
    if screensaver_active and window and window.class and not window.class:match("^com%.tte%.screensaver") then
        stop_screensaver()
    end
end)

hl.on("window.active", function(window)
    if screensaver_active and window and window.class and not window.class:match("^com%.tte%.screensaver") then
        stop_screensaver()
    end
end)

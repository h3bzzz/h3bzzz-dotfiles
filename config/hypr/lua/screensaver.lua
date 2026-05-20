local screensaver_active = false
local screensaver_class = "tte-screensaver"
local home = os.getenv("HOME")

local function start_screensaver()
    screensaver_active = true
    hl.exec_cmd("pkill -f 'kitty --class " .. screensaver_class .. "'; " ..
        home .. "/.config/hypr/screensaver/start-screensaver.sh &")
end

local function stop_screensaver()
    if screensaver_active then
        screensaver_active = false
        hl.exec_cmd("pkill -f 'kitty --class " .. screensaver_class .. "'")
    end
end

_G.start_screensaver = start_screensaver
_G.stop_screensaver = stop_screensaver

hl.on("window.open", function(window)
    if screensaver_active and window.class ~= screensaver_class then
        stop_screensaver()
    end
end)

hl.on("window.active", function()
    if screensaver_active then
        stop_screensaver()
    end
end)

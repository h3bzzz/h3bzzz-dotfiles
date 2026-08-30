-- ~/.config/hypr/lua/binds.lua
-- All keybindings for Rose Pine Hyprland setup
-- Based on official /usr/share/hypr/hyprland.lua API

local terminal    = "ghostty"
local fileManager = "thunar"
local menu        = "~/.config/rofi/launchers/type-3/launcher.sh"
local mainMod     = "SUPER"
local home          = os.getenv("HOME") or os.getenv("USERPROFILE") or "."
local screenshotDir = home .. "/Pictures/screenshots"

-- ============================================================
-- Core binds
-- ============================================================

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal),                          { description = "Open terminal" })
hl.bind(mainMod .. " + Q",     hl.dsp.window.close(),                             { description = "Close active window" })
-- uwsm is not installed and `hyprctl dispatch 'hl.dsp.exit()'` was never a
-- valid dispatcher string, so the old chained shell command was a no-op.
-- hl.dsp.exit() is the real dispatcher.
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit(), { description = "Exit Hyprland" })

-- ============================================================
-- App launchers
-- ============================================================

hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager),                          { description = "Open file manager" })
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }),            { description = "Toggle floating" })
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu),                                  { description = "Open launcher (rofi)" })
-- Quickshell app browser: drops out of the top-left corner under the arch
-- badge in waybar. Rofi stays on SUPER+R as the fallback.
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("qs ipc call launcher toggle 2>/dev/null || " .. menu),      { description = "App browser (quickshell)" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(),                                 { description = "Dwindle pseudotile" })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.layout("togglesplit"),                   { description = "Toggle split" })

hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("/usr/bin/zen-browser"),               { description = "Open Zen browser" })
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("/usr/bin/google-chrome-stable"),      { description = "Open Chrome" })
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd(home .. "/.local/bin/burp"),                  { description = "Open Burp Suite" })
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("/usr/bin/caido"),                      { description = "Open Caido" })
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("rofi -show window -theme ~/.config/rofi/launchers/type-3/style-3.rasi"), { description = "Window switcher" })
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd("/usr/bin/cursor"),                     { description = "Open Cursor editor" })
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("/usr/bin/firefox"),                    { description = "Open Firefox" })
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd("/usr/bin/code"),                       { description = "Open VS Code" })

-- ============================================================
-- Wallpaper picker (quickshell coverflow)
-- ============================================================

hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call wallpaper toggle"), { description = "Pick wallpaper (coverflow)" })

-- ============================================================
-- Screenshots
-- ============================================================

hl.bind(mainMod .. " + Print",         hl.dsp.exec_cmd("hyprshot -m region -o " .. screenshotDir),      { description = "Screenshot region" })
hl.bind("Print",                       hl.dsp.exec_cmd("hyprshot -m output -o " .. screenshotDir),      { description = "Screenshot output" })
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot-annotate.sh"), { description = "Screenshot + annotate (satty)" })
hl.bind(mainMod .. " + SHIFT + I",     hl.dsp.exec_cmd("swayimg --gallery"),                            { description = "Open image gallery" })

-- ============================================================
-- Scratchpad (special workspace)
-- ============================================================

hl.bind(mainMod .. " + M",         hl.dsp.workspace.toggle_special("magic"),              { description = "Toggle scratchpad" })
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.window.move({ workspace = "special:magic" }),      { description = "Move to scratchpad" })

-- Drop-down terminal. A dedicated ghostty instance spawned in autostart.lua
-- and parked on special:dropdown by the rule in rules.lua. Ghostty's own quick
-- terminal cannot be used because toggling it from outside the app needs a
-- `global:` keybind, which is macOS-only.
hl.bind(mainMod .. " + grave",     hl.dsp.workspace.toggle_special("dropdown"),           { description = "Toggle drop-down terminal" })

-- ============================================================
-- Session / utilities
-- ============================================================

hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("pidof hyprlock || hyprlock"),                          { description = "Lock screen" })

-- thornwatch screensaver. CTRL variant starts it on demand without waiting
-- out the idle timer; SHIFT variant is the escape hatch if the saver window
-- ever gets stuck focused.
hl.bind(mainMod .. " + CTRL + ESCAPE",  hl.dsp.exec_cmd("~/.config/hypr/thornwatch/ctl.sh toggle"), { description = "Toggle screensaver" })
hl.bind(mainMod .. " + SHIFT + ESCAPE", hl.dsp.exec_cmd("~/.config/hypr/thornwatch/ctl.sh stop"),   { description = "Kill screensaver" })
-- Quickshell session dropdown, top-right under the waybar power button.
-- SHIFT+ and CTRL+ESCAPE are already taken by the screensaver, so the old
-- full-screen rofi powermenu lives on the power button's right-click instead.
hl.bind(mainMod .. " + ESCAPE",    hl.dsp.exec_cmd("qs ipc call power toggle 2>/dev/null || ~/.config/rofi/powermenu/type-4/powermenu.sh"),                             { description = "Session menu (quickshell)" })
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("swaync-client -t -sw"),                                 { description = "Toggle notification panel" })
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("~/.config/hypr/scripts/clipboard.sh"),                  { description = "Clipboard history" })
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a && notify-send 'Color picked' \"$(wl-paste)\""), { description = "Pick color to clipboard" })

-- ============================================================
-- Focus movement
-- OFFICIAL API: hl.dsp.focus({ direction = "left" })
-- ============================================================

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }),  { description = "Focus left" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "Focus right" })
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }),    { description = "Focus up" })
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }),  { description = "Focus down" })
hl.bind(mainMod .. " + H",     hl.dsp.focus({ direction = "left" }),  { description = "Focus left (vim)" })
hl.bind(mainMod .. " + L",     hl.dsp.focus({ direction = "right" }), { description = "Focus right (vim)" })
hl.bind(mainMod .. " + K",     hl.dsp.focus({ direction = "up" }),    { description = "Focus up (vim)" })
-- SUPER + J was togglesplit, which left vim focus nav missing its down key.
-- togglesplit moved to SUPER + SHIFT + J.
hl.bind(mainMod .. " + J",     hl.dsp.focus({ direction = "down" }),  { description = "Focus down (vim)" })

-- ============================================================
-- Window resize submap
-- Resize mode mirrors the legacy resize submap.
-- ============================================================

hl.bind(mainMod .. " + Z", hl.dsp.submap("resize"), { description = "Enter resize mode" })

hl.define_submap("resize", function()
    hl.bind("right",  hl.dsp.window.resize({ x = 30,  y = 0,   relative = true }), { repeating = true })
    hl.bind("left",   hl.dsp.window.resize({ x = -30, y = 0,   relative = true }), { repeating = true })
    hl.bind("up",     hl.dsp.window.resize({ x = 0,   y = -30, relative = true }), { repeating = true })
    hl.bind("down",   hl.dsp.window.resize({ x = 0,   y = 30,  relative = true }), { repeating = true })
    hl.bind("L",      hl.dsp.window.resize({ x = 30,  y = 0,   relative = true }), { repeating = true })
    hl.bind("H",      hl.dsp.window.resize({ x = -30, y = 0,   relative = true }), { repeating = true })
    hl.bind("K",      hl.dsp.window.resize({ x = 0,   y = -30, relative = true }), { repeating = true })
    hl.bind("J",      hl.dsp.window.resize({ x = 0,   y = 30,  relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("RETURN", hl.dsp.submap("reset"))
end)

-- ============================================================
-- Groups (tabbed windows)
--
-- Omarchy puts the group toggle on SUPER + G; that key is already Chrome
-- here, so the whole cluster shifts to SUPER + SHIFT + G and SUPER + ALT.
-- ============================================================

hl.bind(mainMod .. " + SHIFT + G", hl.dsp.group.toggle(),                       { description = "Toggle window grouping" })
hl.bind(mainMod .. " + ALT + G",   hl.dsp.window.move({ out_of_group = true }), { description = "Move window out of group" })

-- Pull a neighbouring window into the group from the given direction.
hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.move({ into_group = "l" }), { description = "Move window into group on left" })
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.move({ into_group = "r" }), { description = "Move window into group on right" })
hl.bind(mainMod .. " + ALT + up",    hl.dsp.window.move({ into_group = "u" }), { description = "Move window into group above" })
hl.bind(mainMod .. " + ALT + down",  hl.dsp.window.move({ into_group = "d" }), { description = "Move window into group below" })

-- Cycle tabs within the focused group.
hl.bind(mainMod .. " + ALT + TAB",         hl.dsp.group.next(), { description = "Next window in group" })
hl.bind(mainMod .. " + ALT + SHIFT + TAB", hl.dsp.group.prev(), { description = "Previous window in group" })
hl.bind(mainMod .. " + ALT + H",           hl.dsp.group.prev(), { description = "Previous window in group (vim)" })
hl.bind(mainMod .. " + ALT + L",           hl.dsp.group.next(), { description = "Next window in group (vim)" })

hl.bind(mainMod .. " + ALT + mouse_down", hl.dsp.group.next(), { description = "Next window in group" })
hl.bind(mainMod .. " + ALT + mouse_up",   hl.dsp.group.prev(), { description = "Previous window in group" })

-- Jump straight to tab N of the focused group.
for i = 1, 5 do
    hl.bind(mainMod .. " + ALT + " .. tostring(i), hl.dsp.group.active({ index = i }), { description = "Group tab " .. i })
end

-- ============================================================
-- Workspaces
-- OFFICIAL API: hl.dsp.focus({ workspace = i })
-- ============================================================

for i = 1, 10 do
    local key = (i == 10) and "0" or tostring(i)

    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }),        { description = "Workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }),   { description = "Move to workspace " .. i })
end

-- ============================================================
-- Mouse workspace scroll
-- ============================================================

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })

-- ============================================================
-- Mouse move/resize
-- OFFICIAL API: hl.dsp.window.drag() / hl.dsp.window.resize()
-- Must pass { mouse = true } for mouse binds
-- ============================================================

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Move window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

-- ============================================================
-- Media / hardware keys
-- locked=true -> works even when lockscreen/input inhibitor is active
-- repeating=true -> repeats while held
-- ============================================================

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh up"),     { locked = true, repeating = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh down"),   { locked = true, repeating = true, description = "Volume down" })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh mute"),   { locked = true, description = "Mute" })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),         { locked = true, description = "Mic mute" })
hl.bind("XF86MonBrightnessUp",    hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh up"),   { locked = true, repeating = true, description = "Brightness up" })
hl.bind("XF86MonBrightnessDown",  hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh down"), { locked = true, repeating = true, description = "Brightness down" })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),                                   { locked = true, description = "Next track" })
hl.bind("XF86AudioPause",        hl.dsp.exec_cmd("playerctl play-pause"),                             { locked = true, description = "Play/pause" })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"),                             { locked = true, description = "Play/pause" })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),                               { locked = true, description = "Previous track" })

-- ============================================================
-- Daily Bible verse widget
-- ============================================================

hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.local/bin/daily-verse"), { description = "Show verse of the day" })

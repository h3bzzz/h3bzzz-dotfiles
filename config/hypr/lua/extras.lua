-- ~/.config/hypr/lua/extras.lua
-- Binds and toggles that use what the Lua config can do and the old hyprlang
-- config could not: binds that run a function, read compositor state, and
-- change config at runtime -- no helper script, no hyprctl round-trip.
--
-- Everything stateful hangs off the global `Rice` table so scripts can reach
-- it too:  hyprctl eval 'Rice.toggle_game_mode()'

local mainMod = "SUPER"
local scripts = "~/.config/hypr/scripts/"

Rice = Rice or {}

local function toast(text)
    hl.notification.create({ text = text, timeout = 2000 })
end

-- ============================================================
-- Fullscreen / maximize
-- ============================================================

hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }), { description = "Fullscreen" })
hl.bind(mainMod .. " + CTRL + F",  hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }),  { description = "Maximize (keep bar and gaps)" })

-- ============================================================
-- Move the focused window (SUPER + CTRL + direction)
-- SUPER + direction focuses; adding CTRL carries the window along.
-- ============================================================

for key, dir in pairs({ left = "left", right = "right", up = "up", down = "down", H = "left", L = "right", K = "up", J = "down" }) do
    hl.bind(mainMod .. " + CTRL + " .. key, hl.dsp.window.move({ direction = dir }), { description = "Move window " .. dir })
end

-- ============================================================
-- Monitors
-- ============================================================

hl.bind(mainMod .. " + comma",          hl.dsp.focus({ monitor = "-1" }),                      { description = "Focus previous monitor" })
hl.bind(mainMod .. " + period",         hl.dsp.focus({ monitor = "+1" }),                      { description = "Focus next monitor" })
hl.bind(mainMod .. " + SHIFT + comma",  hl.dsp.window.move({ monitor = "-1", follow = true }), { description = "Move window to previous monitor" })
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.window.move({ monitor = "+1", follow = true }), { description = "Move window to next monitor" })

-- ============================================================
-- Per-workspace layout cycling:  dwindle -> scrolling -> monocle
--
-- Layouts are per workspace since Hyprland 0.54, and scrolling (niri-style
-- columns) and monocle (one window at a time) are built in. A workspace rule
-- added at runtime takes effect immediately, so each workspace keeps whatever
-- layout suits what is on it: tiles for code, a scrolling strip for a pile of
-- browser windows, monocle on a small screen.
-- ============================================================

local layouts = { "dwindle", "scrolling", "monocle" }

function Rice.cycle_layout()
    local ws = hl.get_active_workspace()
    if not ws then return end
    local nxt = layouts[1]
    for i, name in ipairs(layouts) do
        if name == ws.tiled_layout then
            nxt = layouts[(i % #layouts) + 1]
            break
        end
    end
    hl.workspace_rule({ workspace = tostring(ws.id), layout = nxt })
    toast("Layout: " .. nxt)
end

hl.bind(mainMod .. " + T", Rice.cycle_layout, { description = "Cycle workspace layout (dwindle / scrolling / monocle)" })

-- Next / previous window. Monocle has its own cycling message because the
-- generic one does not know which window is on top there.
local function cycle(forward)
    return function()
        local ws = hl.get_active_workspace()
        if ws and ws.tiled_layout == "monocle" then
            hl.dispatch(hl.dsp.layout(forward and "cyclenext" or "cycleprev"))
        else
            hl.dispatch(hl.dsp.window.cycle_next({ next = forward }))
        end
    end
end

hl.bind(mainMod .. " + TAB",         cycle(true),  { description = "Next window on workspace" })
hl.bind(mainMod .. " + SHIFT + TAB", cycle(false), { description = "Previous window on workspace" })

-- Scrolling layout: shift the strip, and resize the focused column through
-- its preset widths.
hl.bind(mainMod .. " + bracketleft",  hl.dsp.layout("move -col"),      { description = "Scrolling: view previous column" })
hl.bind(mainMod .. " + bracketright", hl.dsp.layout("move +col"),      { description = "Scrolling: view next column" })
hl.bind(mainMod .. " + equal",        hl.dsp.layout("colresize +conf"), { description = "Scrolling: wider column" })
hl.bind(mainMod .. " + minus",        hl.dsp.layout("colresize -conf"), { description = "Scrolling: narrower column" })

-- ============================================================
-- Game mode
-- Strips everything that costs frames -- animations, blur, shadows, dimming,
-- gaps, rounding -- and puts back exactly what was there before, whatever
-- settings.lua says at the time.
-- ============================================================

local game_keys = {
    ["animations.enabled"]            = false,
    ["decoration.blur.enabled"]       = false,
    ["decoration.shadow.enabled"]     = false,
    ["decoration.dim_inactive"]       = false,
    ["decoration.rounding"]           = 0,
    ["general.gaps_in"]               = 0,
    ["general.gaps_out"]              = 0,
    ["general.border_size"]           = 1,
}

-- "a.b.c" = v  ->  { a = { b = { c = v } } }
local function nest(flat)
    local out = {}
    for key, value in pairs(flat) do
        local node = out
        local parts = {}
        for part in key:gmatch("[^.]+") do parts[#parts + 1] = part end
        for i = 1, #parts - 1 do
            node[parts[i]] = node[parts[i]] or {}
            node = node[parts[i]]
        end
        node[parts[#parts]] = value
    end
    return out
end

-- A profile is a set of config overrides that can be switched on, and
-- switched off again by restoring exactly what was there before it.
local function profile(flag, label, keys)
    local saved = nil
    Rice[flag] = false
    return function()
        if Rice[flag] and saved then
            hl.config(nest(saved))
            saved = nil
            Rice[flag] = false
            toast(label .. " off")
        else
            saved = {}
            for key in pairs(keys) do saved[key] = hl.get_config(key) end
            hl.config(nest(keys))
            Rice[flag] = true
            toast(label .. " on")
        end
    end
end

Rice.toggle_game_mode = profile("game_mode", "Game mode", game_keys)

-- ============================================================
-- Eye candy
-- The Hyprland 0.57 showpieces: frosted-glass blur, wobbly windows, glow.
-- Other blur variants: haze, acrylic, prism, water, aurora, drops,
-- heat_shimmer, fluid_jar, ripple (kawase is the plain default).
-- Off by default -- the glass variant is noticeably heavier than plain blur
-- and this config is tuned for integrated graphics. Flip it on for
-- screenshots or on a machine with a discrete GPU; to make it permanent,
-- copy these keys into settings.lua.
-- ============================================================

Rice.toggle_eye_candy = profile("eye_candy", "Eye candy", {
    ["decoration.blur.variant"]   = "frost",
    ["decoration.blur.size"]      = 6,
    ["decoration.blur.passes"]    = 2,
    ["decoration.blur.vibrancy"]  = 0.25,
    ["decoration.wobble.enabled"] = true,
    ["decoration.glow.enabled"]   = true,
    ["decoration.glow.range"]     = 14,
})

hl.bind(mainMod .. " + CTRL + E", Rice.toggle_eye_candy, { description = "Toggle eye candy (frost blur, wobble, glow)" })

hl.bind(mainMod .. " + CTRL + G", Rice.toggle_game_mode, { description = "Toggle game mode (no animations, blur, gaps)" })

-- ============================================================
-- Session toggles and tools (scripts/toggle.sh, capture.sh, picker.sh)
-- ============================================================

-- Quickshell control centre: clock, vitals, sliders, every toggle below as a
-- tile. The rofi menu on SUPER + X is the fallback when quickshell is down.
hl.bind(mainMod .. " + D",         hl.dsp.exec_cmd("qs ipc call control toggle 2>/dev/null || " .. scripts .. "menu.sh"), { description = "Control centre (quickshell)" })
hl.bind(mainMod .. " + X",         hl.dsp.exec_cmd(scripts .. "menu.sh"),            { description = "Control menu (all toggles and tools)" })
hl.bind(mainMod .. " + slash",     hl.dsp.exec_cmd(scripts .. "keybinds.sh"),        { description = "Keybind cheat sheet" })

hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd(scripts .. "toggle.sh nightlight"), { description = "Toggle night light" })
hl.bind(mainMod .. " + CTRL + I",  hl.dsp.exec_cmd(scripts .. "toggle.sh idle"),       { description = "Toggle caffeine (idle inhibit)" })
hl.bind(mainMod .. " + CTRL + P",  hl.dsp.exec_cmd(scripts .. "toggle.sh power"),      { description = "Cycle power profile" })
hl.bind(mainMod .. " + CTRL + N",  hl.dsp.exec_cmd(scripts .. "toggle.sh dnd"),        { description = "Toggle do not disturb" })

hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(scripts .. "capture.sh record"),  { description = "Start / stop screen recording" })
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(scripts .. "capture.sh ocr"),     { description = "Copy text from screen region (OCR)" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd(scripts .. "capture.sh qr"),      { description = "Scan QR code from screen region" })

hl.bind(mainMod .. " + semicolon", hl.dsp.exec_cmd(scripts .. "picker.sh emoji"),    { description = "Emoji picker" })
hl.bind(mainMod .. " + C",         hl.dsp.exec_cmd(scripts .. "picker.sh calc"),     { description = "Calculator" })

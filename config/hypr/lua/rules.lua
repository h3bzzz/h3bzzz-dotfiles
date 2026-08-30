-- ~/.config/hypr/lua/rules.lua
-- Window rules for Rose Pine Hyprland setup
-- Based on official /usr/share/hypr/hyprland.lua API

-- ============================================================
-- Suppress maximize requests from apps
-- ============================================================

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- ============================================================
-- Opacity tagging
--
-- Rules are evaluated in declaration order, so this runs in three stages:
--   1. tag every window with +default-opacity
--   2. individual apps drop the tag with -default-opacity (see below)
--   3. the surviving tagged windows get the opacity value applied
--
-- Stage 3 lives at the BOTTOM of this file. Anything that opts out must do
-- so between here and there.
-- ============================================================

hl.window_rule({
    name  = "tag-default-opacity",
    match = { class = ".*" },
    tag   = "+default-opacity",
})

-- Opt-outs: fully opaque.
--
-- Traffic inspection -- a translucent proxy window renders request bodies over
-- whatever is behind it, which is both unreadable and a shoulder-surfing risk.
hl.window_rule({
    name  = "opaque-security-tools",
    match = { class = "^(burpsuite|install4j-burp-StartBurp|caido|wireshark|Caido)$" },
    tag   = "-default-opacity",
})

-- Media -- colour and contrast should not be filtered by the compositor.
hl.window_rule({
    name  = "opaque-media",
    match = { class = "^(mpv|vlc|imv|swayimg|com.obsproject.Studio|org.kde.kdenlive|Gimp.*|libresprite|blender)$" },
    tag   = "-default-opacity",
})

-- Browsers -- large surfaces, so this is where the blur re-render cost is
-- worst. Kept opaque while focused, barely dimmed when not.
hl.window_rule({
    name  = "tag-browser",
    match = { class = "((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|[fF]irefox|[zZ]en.*|librewolf)" },
    tag   = "+browser",
})

hl.window_rule({
    name  = "opacity-browser",
    match = { tag = "browser" },
    tag   = "-default-opacity",
    opacity = "1.0 0.98",
})

-- ============================================================
-- Smart gaps: no border/rounding when only one window on workspace
-- ============================================================

hl.window_rule({
    name  = "no-border-wtv1",
    match = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding    = 0,
})

hl.window_rule({
    name  = "no-border-f1",
    match = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding    = 0,
})

-- ============================================================
-- Fix XWayland drag issues
-- ============================================================

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- ============================================================
-- hyprland-run floater (bottom-left)
-- OFFICIAL: move = "20 monitor_h-120" (string expression)
-- ============================================================

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- ============================================================
-- Workspace assignments
-- ============================================================

hl.window_rule({ name = "burpsuite-ws3", match = { class = "^(burpsuite|install4j-burp-StartBurp)$" }, workspace = "3 silent" })
hl.window_rule({ name = "caido-ws3",     match = { class = "^(caido)$" },     workspace = "3 silent" })
hl.window_rule({ name = "wireshark-ws3", match = { class = "^(wireshark)$" }, workspace = "3 silent" })

hl.window_rule({ name = "firefox-ws2", match = { class = "^([Ff]irefox)$" },       workspace = "2" })
hl.window_rule({ name = "zen-ws2",     match = { class = "^([Zz]en)$" },           workspace = "2" })
hl.window_rule({ name = "chrome-ws2",  match = { class = "^(google-chrome.*)$" },  workspace = "2" })

-- ============================================================
-- Floating rules — dialogs, pickers, etc.
-- ============================================================

hl.window_rule({
    name  = "float-nm-editor",
    match = { class = "nm-connection-editor" },
    float  = true,
    center = true,
})

hl.window_rule({
    name  = "float-blueman",
    match = { class = "blueman-manager" },
    float  = true,
    center = true,
})

hl.window_rule({
    name  = "float-pavucontrol",
    match = { class = "pavucontrol" },
    float  = true,
    center = true,
})

hl.window_rule({
    name  = "float-file-progress",
    match = { title = "File Operation Progress" },
    float = true,
})

hl.window_rule({
    name  = "float-confirm-replace",
    match = { title = "Confirm to replace files" },
    float = true,
})

hl.window_rule({
    name  = "float-auth-required",
    match = { title = "Authentication Required" },
    float = true,
})

-- ============================================================
-- thornwatch screensaver
--
-- Spawned by ~/.config/hypr/thornwatch/ctl.sh as a ghostty window carrying a
-- dedicated app-id. It has to be fullscreen, pinned so a workspace switch
-- cannot reveal the desktop behind it, and focused so keystrokes wake it
-- instead of landing in whatever was open. Emergency exit is SUPER+SHIFT+ESC.
-- ============================================================

hl.window_rule({
    name         = "thornwatch-saver",
    match        = { class = "^(dev\\.h3bzzz\\.thornwatch)$" },
    tag          = "-default-opacity",
    fullscreen   = true,
    pin          = true,
    stay_focused = true,
    no_anim      = true,
    no_dim       = true,
    border_size  = 0,
    rounding     = 0,
    opacity      = "1.0 1.0",
})

-- ============================================================
-- Stage 3: apply opacity to everything that did not opt out.
-- MUST stay last in this file -- see "Opacity tagging" above.
-- ============================================================

hl.window_rule({
    name    = "apply-default-opacity",
    match   = { tag = "default-opacity" },
    opacity = "1.0 0.92",
})

-- ============================================================
-- Drop-down terminal
--
-- A dedicated ghostty instance (spawned in autostart.lua with its own app-id)
-- parked on a special workspace. SUPER+grave slides it in and out.
--
-- Ghostty's built-in quick terminal is deliberately not used: toggling it from
-- outside the app requires `keybind = global:`, which is macOS-only. See the
-- DROP-DOWN TERMINAL note in ~/.config/ghostty/config.
-- ============================================================

-- NOTE: `size` and `move` are deliberately absent. Hyprland ignores both for
-- windows it places on a special workspace (tested: the window stays centred at
-- whatever size the client asked for). Geometry therefore comes from ghostty's
-- own --window-width/--window-height in autostart.lua, which is deterministic.
hl.window_rule({
    name      = "dropdown-terminal",
    match     = { class = "^(dev\\.h3bzzz\\.dropdown)$" },
    workspace = "special:dropdown silent",
    float     = true,
})

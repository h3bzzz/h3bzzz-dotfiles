-- ~/.config/hypr/lua/settings.lua
-- Monitor, general, decoration, animations, input, misc, cursor settings
-- Based on official /usr/share/hypr/hyprland.lua API

-- ============================================================
-- Palette
-- ============================================================
--
-- lua/colors.lua is regenerated from the current wallpaper by
-- ~/.config/hypr/scripts/apply-theme.sh, which then calls `hyprctl reload`.
--
-- The cache entry is dropped first because a reload may reuse the same Lua
-- state, and a cached `colors` would pin the config to the palette that was
-- on disk when Hyprland started.
--
-- pcall, and the Rose Pine fallback, because this file must stay loadable
-- even if colors.lua is missing or is caught half-written: a Lua error here
-- costs the whole config, keybinds included.
package.loaded["colors"] = nil
local ok, colors = pcall(require, "colors")
if not ok or type(colors) ~= "table" or colors.pine == nil then
    colors = {
        base    = "191724", surface = "1f1d2e", overlay = "26233a",
        muted   = "6e6a86", subtle  = "908caa", text    = "e0def4",
        love    = "eb6f92", gold    = "f6c177", rose    = "ebbcba",
        pine    = "31748f", foam    = "9ccfd8", iris    = "c4a7e7",
    }
end

-- Hyprland colours are `rgba(rrggbbaa)`; the palette stores bare hex so one
-- entry can carry any opacity.
local function rgba(slot, alpha)
    return "rgba(" .. colors[slot] .. alpha .. ")"
end

local function rgb(slot)
    return "rgb(" .. colors[slot] .. ")"
end

-- ============================================================
-- Monitor: use preferred mode for any output
-- ============================================================

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- ============================================================
-- General settings
-- ============================================================

hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 4,

        border_size = 2,

        -- Rose Pine active border: pine -> iris gradient
        col = {
            active_border   = { colors = {rgba("pine", "ee"), rgba("iris", "ee")}, angle = 45 },
            inactive_border = rgba("muted", "44"),
        },

        resize_on_border = true,
        -- Tearing only takes effect for windows carrying an `immediate` rule,
        -- and there are none. Off, so the flag doesn't read as enabled.
        allow_tearing    = false,
        layout           = "dwindle",
    }
})

-- ============================================================
-- Decoration
-- ============================================================

hl.config({
    decoration = {
        rounding       = 8,
        rounding_power = 2.0,

        -- Opacity is no longer applied globally here. A blanket inactive_opacity
        -- makes every unfocused window translucent, which forces the blur pass
        -- to re-render whatever sits underneath it -- the single most expensive
        -- thing this config asks of a UHD 620. rules.lua now tags windows and
        -- applies opacity per app, so media, video and traffic-inspection tools
        -- stay fully opaque and cost nothing.
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        -- Shadow -- subtle depth without visual clutter
        shadow = {
            enabled        = true,
            range          = 12,
            render_power   = 3,
            color          = 0x73000000,
            color_inactive = 0x33000000,
            offset         = { 0, 4 },
        },

        -- Blur -- enabled but tasteful; terminal glass effect
        -- Blur cost scales with size * passes. 6/2 is a discrete-GPU setting;
        -- 4/1 keeps the glass look on integrated graphics.
        blur = {
            enabled           = true,
            size              = 4,
            passes            = 1,
            noise             = 0.02,
            contrast          = 0.9,
            brightness        = 0.85,
            xray              = false,
            ignore_opacity    = false,
            new_optimizations = true,
            special           = true,
        },

        -- Dim inactive windows slightly for that "focused work" feel
        dim_inactive = true,
        dim_strength = 0.08,
        dim_special  = 0.4,
    }
})

-- ============================================================
-- Animations
-- OFFICIAL API: hl.curve() + hl.animation(), NOT inside hl.config()
-- See /usr/share/hypr/hyprland.lua for reference
-- ============================================================

hl.curve("easeOut",    { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.0}    } })
hl.curve("easeInOut",  { type = "bezier", points = { {0.45, 0.05}, {0.55, 0.95} } })
hl.curve("snap",       { type = "bezier", points = { {0.1,  0},   {0.9,  1}    } })
hl.curve("overshot",   { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05}  } })

hl.animation({ leaf = "windows",     enabled = true, speed = 3,  bezier = "overshot",  style = "popin 92%" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 3,  bezier = "overshot",  style = "popin 92%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2,  bezier = "easeInOut", style = "popin 92%" })

hl.animation({ leaf = "border",      enabled = true, speed = 5,  bezier = "easeOut" })
hl.animation({ leaf = "borderangle",  enabled = true, speed = 50, bezier = "easeInOut", loop = true })

hl.animation({ leaf = "fade",         enabled = true, speed = 3,  bezier = "easeOut" })
hl.animation({ leaf = "fadeIn",       enabled = true, speed = 3,  bezier = "easeOut" })
hl.animation({ leaf = "fadeOut",      enabled = true, speed = 2,  bezier = "easeInOut" })

hl.animation({ leaf = "workspaces",   enabled = true, speed = 3,  bezier = "snap",     style = "slide" })

hl.animation({ leaf = "layers",       enabled = true, speed = 2,  bezier = "easeOut" })
hl.animation({ leaf = "layersIn",    enabled = true, speed = 3,  bezier = "easeOut",  style = "fade" })
hl.animation({ leaf = "layersOut",   enabled = true, speed = 2,  bezier = "easeInOut", style = "fade" })

-- ============================================================
-- Workspace rules (smart gaps)
-- OFFICIAL API: hl.workspace_rule(), NOT inside hl.config()
-- ============================================================

hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })

-- ============================================================
-- Dwindle layout
-- ============================================================

hl.config({
    dwindle = {
        preserve_split = true,

        -- Always open the new window on the right/bottom rather than wherever
        -- the cursor happens to be, so tiling is positional, not pointer-driven.
        force_split    = 2,
    }
})

-- ============================================================
-- Master layout
-- ============================================================

hl.config({
    master = {
        new_status = "master",
    }
})

-- ============================================================
-- Misc
-- ============================================================

hl.config({
    misc = {
        force_default_wallpaper      = 0,
        disable_hyprland_logo        = true,
        background_color             = 0x191724,  -- Rose Pine base: kill empty-workspace flash
        vrr                          = 1,
        mouse_move_enables_dpms      = true,
        key_press_enables_dpms       = true,
        animate_manual_resizes       = false,
        animate_mouse_windowdragging = false,
        initial_workspace_tracking   = 0,
        focus_on_activate            = false,

        disable_splash_rendering     = true,
        disable_scale_notification   = true,

        -- Hyprland pings a client 3 times before declaring it
        -- application-not-responding, instead of the default 1. Stops a busy
        -- Electron app from being flagged during a single long frame.
        anr_missed_pings             = 3,

        -- Focusing a window that is under a fullscreen one drops the
        -- fullscreen instead of leaving the new focus invisible behind it.
        on_focus_under_fullscreen    = 1,

        -- If hyprlock dies while holding the session lock, let a fresh client
        -- re-acquire it rather than stranding the session on the lockdead
        -- screen with no way back in.
        allow_session_lock_restore   = true,
    }
})

-- ============================================================
-- Input
-- ============================================================

hl.config({
    input = {
        kb_layout  = "us",
        kb_options = "caps:escape",

        follow_mouse = 1,
        sensitivity  = 0,

        repeat_rate  = 40,
        repeat_delay = 250,

        touchpad = {
            natural_scroll       = false,
            disable_while_typing = true,
            tap_to_click         = true,
        },
    }
})

-- ============================================================
-- Gestures
-- OFFICIAL API: hl.gesture(), NOT inside hl.config()
-- ============================================================

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- ============================================================
-- Cursor
-- ============================================================

hl.config({
    cursor = {
        no_hardware_cursors = false,
        enable_hyprcursor   = true,
        no_warps            = false,

        -- Get the pointer out of the way while typing; any mouse movement
        -- brings it straight back.
        hide_on_key_press        = true,

        -- Move the pointer onto the workspace being switched to, so the next
        -- click and follow_mouse both act on the workspace you are looking at.
        warp_on_change_workspace = 1,
    }
})

-- ============================================================
-- Bind behaviour
-- ============================================================

hl.config({
    binds = {
        -- Leaving a workspace closes the scratchpad overlay behind you rather
        -- than leaving it floating over the workspace you just moved to.
        hide_special_on_workspace_change = true,
    }
})

-- ============================================================
-- XWayland / ecosystem
-- ============================================================

hl.config({
    xwayland = {
        -- Hand XWayland a scale of 1 and let X11 apps draw at native size
        -- instead of being rendered small and stretched by the compositor.
        -- Inert while every monitor sits at scale 1; correct the moment one
        -- does not. Deliberately NOT paired with GDK_SCALE, which would double
        -- GTK chrome on this 1080p panel.
        force_zero_scaling = true,
    },

    ecosystem = {
        no_update_news = true,
    },
})

-- ============================================================
-- Groups (tabbed windows) -- Rose Pine
-- ============================================================

hl.config({
    group = {
        col = {
            border_active   = { colors = {rgba("pine", "ee"), rgba("iris", "ee")}, angle = 45 },
            border_inactive = rgba("muted", "44"),
        },

        groupbar = {
            enabled              = true,
            -- A group of one is just a window; don't spend a title bar on it.
            disable_when_only    = true,

            font_family          = "monospace",
            font_size            = 11,
            font_weight_active   = "bold",
            font_weight_inactive = "normal",

            height               = 20,
            indicator_height     = 2,
            indicator_gap        = 4,
            gaps_in              = 4,
            gaps_out             = 0,
            rounding             = 4,

            text_color           = rgb("text"),
            text_color_inactive  = rgba("subtle", "90"),
            col = {
                active   = rgba("pine", "66"),
                inactive = rgba("overlay", "66"),
            },

            gradients                 = true,
            gradient_rounding         = 4,
            gradient_round_only_edges = false,

            -- Middle-clicking a tab is too easy to do by accident for
            -- something that closes a window with no confirmation.
            middle_click_close        = false,
        },
    }
})

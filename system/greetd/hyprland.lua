-- /etc/greetd/hyprland.lua -- Hyprland config for the login screen only.
--
-- Started by /etc/greetd/greeter-session as the `greeter` user. Its one job
-- is to put ReGreet on the right monitor and get out of the way; it exits as
-- soon as ReGreet does (the user's real session is started by greetd).
--
-- Monitor policy
--   * The LG is the main display: the login UI is drawn there.
--   * The ViewSonic VX2252 (DP-3) is secondary: it shows only the dark
--     background colour (no mirroring, see the hyprland.start handler).
--   The LG currently hangs off the driverless AMD card and shows up as
--   "Unknown-1" with no EDID, and after moving its cable to the Intel board
--   it will be DP-1/DP-2/HDMI-A-1. So the rule is "main = whatever is NOT
--   the ViewSonic", resolved at start-up rather than hard-coded.

local SECONDARY_NAME = "DP-3"
local SECONDARY_DESC = "VX2252" -- matched against the EDID description

-- Static layout: the ViewSonic to the right of whatever else is plugged in.
-- Fixed positions on purpose; "auto-right" would land at 0x0 if DP-3 came up
-- first and the LG would then be placed on top of it.
hl.monitor({ output = SECONDARY_NAME, mode = "1920x1080@60", position = "1920x0", scale = 1 })
hl.monitor({ output = "",             mode = "preferred",     position = "0x0",    scale = 1 })

-- GTK: do not wait on xdg-desktop-portal (greeter has none -> 20 s stall).
hl.env("GTK_USE_PORTAL", "0")
hl.env("GDK_DEBUG", "no-portals")
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
    general = {
        gaps_in     = 0,
        gaps_out    = 0,
        border_size = 0,
        layout      = "dwindle",
    },
    decoration = {
        rounding     = 0,
        dim_inactive = false,
        blur   = { enabled = false },
        shadow = { enabled = false },
    },
    animations = { enabled = false },
    input = {
        -- Same keymap as the desktop (settings.lua) so the password is typed
        -- the way it is typed everywhere else on this machine.
        kb_layout    = "us",
        kb_options   = "caps:escape",
        repeat_rate  = 40,
        repeat_delay = 250,
        numlock_by_default = false,
    },
    cursor = {
        inactive_timeout = 4, -- hide the pointer when it is not moving
    },
    misc = {
        disable_hyprland_logo           = true,
        disable_splash_rendering        = true,
        disable_hyprland_guiutils_check = true,
        force_default_wallpaper         = 0,
        -- Palette base: what shows for the frame or two before ReGreet maps.
        background_color                = "rgb(0d141c)",
        disable_scale_notification      = true,
        mouse_move_enables_dpms         = true,
        key_press_enables_dpms          = true,
        vrr                             = 0,
    },
    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },
    xwayland = { enabled = false },
})

-- The greeter binary. Overridable so preview.sh can run `regreet --demo`
-- with the staged config inside a nested Hyprland window.
local regreet_cmd = os.getenv("GREETER_REGREET_CMD") or "regreet"

local function is_secondary(m)
    if m.name == SECONDARY_NAME then return true end
    local desc = m.description or ""
    return desc:find(SECONDARY_DESC, 1, true) ~= nil
end

local function pick_monitors()
    local main, secondary
    for _, m in ipairs(hl.get_monitors()) do
        if is_secondary(m) then
            secondary = secondary or m
        else
            main = main or m
        end
    end
    -- Only the ViewSonic connected: it is the main display after all.
    if not main then
        main, secondary = secondary, nil
    end
    return main, secondary
end

hl.on("hyprland.start", function()
    local rules = { fullscreen = true }

    -- Everything that only *improves* placement is wrapped in pcall: a
    -- surprise from the monitor API must never cost us the login screen.
    local ok, main, secondary = pcall(pick_monitors)
    if ok and main then
        rules.monitor = main.name
        -- The ViewSonic is deliberately NOT mirrored: the LG is a simpledrm
        -- output on another GPU, and a cross-GPU mirror is the one part of
        -- this that could misbehave at boot. It just shows the dark palette
        -- base (misc.background_color) behind the login on the LG.
    end

    -- When ReGreet exits (session started, or it crashed) this compositor
    -- exits too, with status 0; greetd then either runs the session or
    -- restarts the greeter.
    hl.exec_cmd(regreet_cmd .. "; hyprctl dispatch 'hl.dsp.exit()'", rules)
end)

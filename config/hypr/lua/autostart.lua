-- ~/.config/hypr/lua/autostart.lua
-- Autostart programs and environment variables for Rose Pine Hyprland setup
-- Based on official /usr/share/hypr/hyprland.lua API

-- ============================================================
-- Environment variables
-- OFFICIAL API: hl.env("KEY", "VAL")
-- ============================================================

local home = os.getenv("HOME") or "."

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRSHOT_DIR", home .. "/Pictures/screenshots")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("MOZ_DBUS_REMOTE", "1")

-- Electron/Chromium on Wayland. NIXOS_OZONE_WL is NixOS-only; the portable
-- hint is what Arch builds actually read.
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")

-- Screen sharing (Meet, Discord, Zoom) resolves the portal backend from these.
-- Without them xdg-desktop-portal picks the wrong impl and capture fails.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- ============================================================
-- Autostart
-- OFFICIAL API: hl.on("hyprland.start", function() ... end)
-- hl.exec_cmd() spawns asynchronously (no & needed)
-- ============================================================

hl.on("hyprland.start", function()
    -- No systemctl/dbus-update-activation-environment calls here: Hyprland
    -- now exports WAYLAND_DISPLAY et al to systemd --user and the dbus
    -- activation environment itself, and starts hyprland-session.target.
    -- The wiki asks for leftover manual calls to be removed.

    -- Polkit agent: the password prompt for privileged GUI actions (mounting
    -- a drive in thunar, editing a connection, pkexec). Without it those
    -- actions fail silently.
    hl.exec_cmd("systemctl --user start hyprpolkitagent.service")

    -- Night light. hyprsunset.conf carries the day / evening schedule.
    hl.exec_cmd("command -v hyprsunset >/dev/null 2>&1 && hyprsunset")

    -- Status bar (waybar — Rose Pine themed in ~/.config/waybar)
    hl.exec_cmd("waybar")

    -- App dock (quickshell — Rose Pine themed in ~/.config/quickshell)
    hl.exec_cmd("command -v quickshell >/dev/null 2>&1 && quickshell -p ~/.config/quickshell/shell.qml")

    -- Notification daemon (swaync — waybar bell + panel depend on it)
    hl.exec_cmd("swaync")

    -- On-screen volume/brightness bar (wob reads the per-instance fifo)
    hl.exec_cmd("~/.config/hypr/scripts/osd-wob.sh")

    -- Wallpaper daemon
    hl.exec_cmd("hyprpaper")

    -- Idle management (dim -> lock -> dpms off)
    hl.exec_cmd("hypridle")

    -- Terminal
    hl.exec_cmd("ghostty")

    -- The drop-down terminal needs nothing here: it is ghostty's own quick
    -- terminal, which lives in the instance above (or is D-Bus-activated on
    -- demand). SUPER+grave in binds.lua toggles it.

    -- Clipboard persistence (keeps clipboard after app closes)
    hl.exec_cmd("command -v wl-clip-persist >/dev/null 2>&1 && wl-clip-persist --clipboard regular")

    -- Clipboard history store
    hl.exec_cmd("command -v wl-paste >/dev/null 2>&1 && command -v cliphist >/dev/null 2>&1 && wl-paste --type text --watch cliphist store")

    -- Daily Bible verse widget (layer-shell popup; exits on dismiss)
    hl.exec_cmd("~/.local/bin/daily-verse-boot")

    -- Repaint the verse on the first wake of a new day. A laptop suspends
    -- far more often than it reboots, so login alone is not enough.
    hl.exec_cmd("~/.local/bin/daily-verse-resume")
end)

-- Optional: run something on shutdown
-- hl.on("hyprland.shutdown", function()
--     hl.exec_cmd("notify-send 'Rose Pine session ended'")
-- end)

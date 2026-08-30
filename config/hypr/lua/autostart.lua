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
    -- Push the session environment into systemd --user and the dbus activation
    -- environment before anything else starts. Portals and user services are
    -- spawned by systemd, which otherwise never sees WAYLAND_DISPLAY et al --
    -- that mismatch is the usual cause of slow first launches and dead portals.
    hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")

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

    -- Drop-down terminal. A second, dedicated ghostty instance that lives on
    -- the special:dropdown workspace and is toggled with SUPER+grave.
    -- --gtk-single-instance=false is required: routed through the instance
    -- above, the new surface would inherit that instance's app-id and the
    -- window rule in rules.lua would never match it.
    hl.exec_cmd("ghostty --class=dev.h3bzzz.dropdown --gtk-single-instance=false "
                .. "--initial-window=true --window-width=185 --window-height=20 "
                .. "--window-decoration=none --background-opacity=0.94")

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
